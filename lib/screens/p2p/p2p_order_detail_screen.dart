import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../dto/p2p/p2p_order_create_request.dart';
import '../../dto/p2p/p2p_order_dto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/p2p_order_detail_provider.dart';
import '../../providers/p2p_order_provider.dart';
import '../../services/api_client.dart';

class P2POrderDetailScreen extends StatelessWidget {
  final int orderId;

  const P2POrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => P2POrderDetailProvider(ApiClient().dio)..loadOrder(orderId),
      child: _P2POrderDetailView(orderId: orderId),
    );
  }
}

class _P2POrderDetailView extends StatefulWidget {
  final int orderId;
  const _P2POrderDetailView({required this.orderId});

  @override
  State<_P2POrderDetailView> createState() => _P2POrderDetailViewState();
}

class _P2POrderDetailViewState extends State<_P2POrderDetailView> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Consumer<P2POrderDetailProvider>(
      builder: (context, provider, child) {
        final order = provider.currentOrder;

        if (order != null) {
          final marketProvider = context.read<P2POrderProvider?>();
          marketProvider?.cacheTrackedOrder(order);
        }

        final body = provider.isLoading && order == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => provider.loadOrder(widget.orderId),
                child: order == null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 160),
                          Center(child: Text('No se pudo cargar la orden.')),
                        ],
                      )
                    : _OrderDetailContent(
                        order: order,
                        isProcessing: provider.isProcessing,
                        isRefreshing: provider.isLoading,
                        onMarkPaid: () => _handleAction(
                          context,
                          () => provider.markAsPaid(order.id),
                          'Orden marcada como pagada.',
                        ),
                        onRelease: () => _handleAction(
                          context,
                          () => provider.releaseOrder(order.id),
                          'Has liberado los TrueCoins.',
                        ),
                        onRefreshOrder: () => _handleManualRefresh(provider),
                        authUserId: auth.user?.id,
                      ),
              );

        return Scaffold(
          appBar: AppBar(title: Text('Orden P2P #${widget.orderId}')),
          body: Column(
            children: [
              if (provider.isLoading) const LinearProgressIndicator(minHeight: 2),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleManualRefresh(P2POrderDetailProvider provider) async {
    try {
      await provider.loadOrder(widget.orderId);
    } on DioException catch (error) {
      if (!mounted) return;
      _showError(context, _mapDioError(error));
    } catch (error) {
      if (!mounted) return;
      _showError(context, error.toString());
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } on DioException catch (error) {
      if (!context.mounted) return;
      _showError(context, _mapDioError(error));
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error.toString());
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _mapDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return error.message ?? 'Ocurrió un error.';
  }
}

class _OrderDetailContent extends StatelessWidget {
  final P2POrderDto order;
  final bool isProcessing;
  final bool isRefreshing;
  final Future<void> Function() onMarkPaid;
  final Future<void> Function() onRelease;
  final Future<void> Function() onRefreshOrder;
  final int? authUserId;

  const _OrderDetailContent({
    required this.order,
    required this.isProcessing,
    required this.isRefreshing,
    required this.onMarkPaid,
    required this.onRelease,
    required this.onRefreshOrder,
    required this.authUserId,
  });

  @override
  Widget build(BuildContext context) {
    final payerId = _payerUserId(order);
    final releaserId = _releaserUserId(order);
    final canMarkPaid = _canMarkPaid(order, authUserId, payerId);
    final canRelease = _canRelease(order, authUserId, releaserId);
    final showPaymentQr = _shouldShowPaymentQr(order, authUserId, payerId);

    final actionButtons = <Widget>[
      if (canMarkPaid)
        ElevatedButton.icon(
          onPressed: isProcessing ? null : () => onMarkPaid(),
          icon: isProcessing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.payments_outlined),
          label: Text(isProcessing ? 'Procesando...' : 'Marcar como pagado'),
        ),
      if (canRelease)
        ElevatedButton.icon(
          onPressed: isProcessing ? null : () => onRelease(),
          icon: isProcessing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_open_outlined),
          label: Text(isProcessing ? 'Procesando...' : 'Liberar TrueCoins'),
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _InfoCard(
          order: order,
          isRefreshing: isRefreshing,
          onRefresh: onRefreshOrder,
        ),
        const SizedBox(height: 16),
        _StakeholdersCard(
          order: order,
          payerId: payerId,
          releaserId: releaserId,
        ),
        if (showPaymentQr) ...[
          const SizedBox(height: 16),
          _PaymentQrCard(
            order: order,
            payerId: payerId,
            releaserId: releaserId,
          ),
        ],
        if (actionButtons.isNotEmpty) ...[
          const SizedBox(height: 24),
          ...actionButtons.map(
            (button) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: button,
            ),
          ),
        ],
      ],
    );
  }

  int? _payerUserId(P2POrderDto order) {
    if (order.type == P2POrderType.deposit) {
      return order.creatorUserId;
    }
    return order.counterpartyUserId;
  }

  int? _releaserUserId(P2POrderDto order) {
    if (order.type == P2POrderType.deposit) {
      return order.counterpartyUserId;
    }
    return order.creatorUserId;
  }

  bool _canMarkPaid(P2POrderDto order, int? userId, int? payerId) {
    return userId != null &&
        payerId != null &&
        order.status == P2POrderStatus.matched &&
        userId == payerId;
  }

  bool _canRelease(P2POrderDto order, int? userId, int? releaserId) {
    return userId != null &&
        releaserId != null &&
        order.status == P2POrderStatus.paid &&
        userId == releaserId;
  }

  bool _shouldShowPaymentQr(
      P2POrderDto order, int? userId, int? payerId) {
    return userId != null &&
        payerId != null &&
        order.status == P2POrderStatus.matched &&
        userId == payerId;
  }
}

class _InfoCard extends StatelessWidget {
  final P2POrderDto order;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  const _InfoCard({
    required this.order,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _typeLabel(order.type),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(_statusLabel(order.status)),
                      backgroundColor:
                        _statusColor(order.status).withValues(alpha: 0.15),
                    ),
                    IconButton(
                      tooltip: 'Actualizar orden',
                      onPressed:
                          isRefreshing ? null : () => onRefresh(),
                      icon: isRefreshing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Monto en Bs', value: 'Bs ${order.amountBob.toStringAsFixed(2)}'),
            _InfoRow(label: 'TrueCoins', value: order.amountTrueCoins.toStringAsFixed(2)),
            _InfoRow(label: 'TC/BOB', value: order.rate.toStringAsFixed(4)),
            _InfoRow(label: 'Metodo de pago', value: order.paymentMethod ?? 'N/D'),
            _InfoRow(label: 'Creada', value: _formatDate(order.createdAt)),
          ],
        ),
      ),
    );
  }

  String _typeLabel(int type) {
    return type == P2POrderType.deposit
        ? 'Deposit · Comprar TrueCoins'
        : 'Withdraw · Vender TrueCoins';
  }

  String _statusLabel(int status) {
    switch (status) {
      case P2POrderStatus.pending:
        return 'Pending';
      case P2POrderStatus.matched:
        return 'Taken';
      case P2POrderStatus.paid:
        return 'Paid';
      case P2POrderStatus.released:
        return 'Released';
      case P2POrderStatus.cancelled:
        return 'Cancelled';
      case P2POrderStatus.disputed:
        return 'Disputed';
      default:
        return 'Desconocido';
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case P2POrderStatus.pending:
        return Colors.orange;
      case P2POrderStatus.matched:
        return Colors.blue;
      case P2POrderStatus.paid:
        return Colors.deepPurple;
      case P2POrderStatus.released:
        return Colors.green;
      case P2POrderStatus.cancelled:
        return Colors.red;
      case P2POrderStatus.disputed:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }
}

class _StakeholdersCard extends StatelessWidget {
  final P2POrderDto order;
  final int? payerId;
  final int? releaserId;

  const _StakeholdersCard({
    required this.order,
    required this.payerId,
    required this.releaserId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Participantes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Creador', value: '#${order.creatorUserId}'),
            _InfoRow(
              label: 'Contraparte',
              value: order.counterpartyUserId != null
                  ? '#${order.counterpartyUserId}'
                  : 'Aún sin asignar',
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Debe pagar',
              value: payerId != null ? 'Usuario #$payerId' : 'En espera de contraparte',
            ),
            _InfoRow(
              label: 'Debe liberar',
              value: releaserId != null ? 'Usuario #$releaserId' : 'En espera de contraparte',
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentQrCard extends StatelessWidget {
  final P2POrderDto order;
  final int? payerId;
  final int? releaserId;

  const _PaymentQrCard({
    required this.order,
    required this.payerId,
    required this.releaserId,
  });

  @override
  Widget build(BuildContext context) {
    final payload = {
      'orderId': order.id.toString(),
      'type': order.type == P2POrderType.deposit ? 'deposit' : 'withdraw',
      'amountBob': order.amountBob.toStringAsFixed(2),
      'amountTC': order.amountTrueCoins.toStringAsFixed(2),
      'payerId': payerId?.toString() ?? '',
      'releaserId': releaserId?.toString() ?? '',
    };
    final qrData = payload.entries.map((e) => '${e.key}=${e.value}').join('&');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR para pago en bolivianos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Monto: Bs ${order.amountBob.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Center(
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escanea este código para realizar la transferencia en BOB.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
