import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dto/p2p/p2p_order_create_request.dart';
import '../../dto/p2p/p2p_order_dto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/p2p_order_provider.dart';
import 'p2p_order_detail_screen.dart';

class P2PMarketScreen extends StatefulWidget {
  const P2PMarketScreen({super.key});

  @override
  State<P2PMarketScreen> createState() => _P2PMarketScreenState();
}

class _P2PMarketScreenState extends State<P2PMarketScreen> {
  bool _didFetch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrderBook());
  }

  Future<void> _loadOrderBook() async {
    if (_didFetch) return;
    _didFetch = true;
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    final provider = context.read<P2POrderProvider>();
    await provider.fetchOrderBook();
    await provider.refreshTrackedOrders();
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return error.message ?? 'No se pudo completar la acción.';
    }
    return 'No se pudo completar la acción.';
  }

  Future<void> _handleTakeOrder(P2POrderDto order) async {
    final provider = context.read<P2POrderProvider>();
    try {
      await provider.takeOrder(order.id);
      if (!mounted) return;
      _openDetail(order.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapError(error))));
    }
  }

  void _openDetail(int orderId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => P2POrderDetailScreen(orderId: orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<P2POrderProvider>();
    final userId = auth.user?.id;
    final orders = provider.getOrdersForUser(userId);
    final bool isLoading = provider.isLoadingOrderBook;
    final takingOrderId = provider.takingOrderId;

    Widget body;
    if (isLoading && orders.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: _refreshAll,
        child: orders.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No hay órdenes disponibles en este momento.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final isParticipant =
                      userId != null &&
                      (order.creatorUserId == userId ||
                          (order.counterpartyUserId != null &&
                              order.counterpartyUserId == userId));
                  final isProcessing = takingOrderId == order.id;
                  final isDisabled = provider.isTakingOrder && !isProcessing;
                  return _OrderCard(
                    order: order,
                    isParticipant: isParticipant,
                    isProcessing: isProcessing,
                    disableWhileBusy: isDisabled,
                    onTakeOrder: isParticipant
                        ? null
                        : () => _handleTakeOrder(order),
                    onViewDetail: isParticipant
                        ? () => _openDetail(order.id)
                        : null,
                  );
                },
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mercado P2P')),
      body: Column(
        children: [
          if (isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final P2POrderDto order;
  final bool isParticipant;
  final bool isProcessing;
  final bool disableWhileBusy;
  final VoidCallback? onTakeOrder;
  final VoidCallback? onViewDetail;

  const _OrderCard({
    required this.order,
    required this.isParticipant,
    required this.isProcessing,
    required this.disableWhileBusy,
    this.onTakeOrder,
    this.onViewDetail,
  });

  bool get _isDeposit => order.type == P2POrderType.deposit;

  Color get _accentColor => _isDeposit ? Colors.green : Colors.orange;

  IconData get _icon => _isDeposit ? Icons.arrow_upward : Icons.arrow_downward;

  String get _typeLabel => _isDeposit
      ? 'Usuario quiere COMPRAR TrueCoins (Deposit)'
      : 'Usuario quiere VENDER TrueCoins (Withdraw)';

  String _formatDouble(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _accentColor.withOpacity(0.15),
                  child: Icon(_icon, color: _accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _typeLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (isParticipant)
                  Chip(
                    label: const Text('Tu orden'),
                    backgroundColor: Colors.blueGrey.withOpacity(0.15),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Monto en Bs: ${_formatDouble(order.amountBob)}'),
            Text('TrueCoins: ${_formatDouble(order.amountTrueCoins)}'),
            Text('TC/BOB: ${_formatDouble(order.rate)}'),
            if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty)
              Text('Pago: ${order.paymentMethod}'),
            const SizedBox(height: 8),
            Text(
              'Creado por usuario #${order.creatorUserId} · ${_formatDate(order.createdAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (!isParticipant)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isProcessing || disableWhileBusy)
                      ? null
                      : onTakeOrder,
                  child: isProcessing
                      ? const Text('Procesando...')
                      : const Text('Tomar orden'),
                ),
              ),
            if (isParticipant && onViewDetail != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onViewDetail,
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Ver detalle'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
