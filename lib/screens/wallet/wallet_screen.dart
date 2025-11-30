import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/market_provider.dart';
import '../../providers/wallet_provider.dart';

import '../../providers/p2p_order_provider.dart';
import '../../dto/p2p/p2p_order_create_request.dart';
import '../p2p/p2p_order_detail_screen.dart';

enum WalletOperationType { deposit, withdraw }

class WalletScreen extends StatefulWidget {
  final WalletOperationType operationType;

  const WalletScreen({
    super.key,
    this.operationType = WalletOperationType.deposit,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _bobController = TextEditingController();
  double? _bobAmount;

  static const double _trueCoinsPerDollar = 10; // 1 USD = 10 TrueCoins

  bool get _isDeposit => widget.operationType == WalletOperationType.deposit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final market = Provider.of<MarketProvider>(context, listen: false);
      market.fetchRate();
      market.startAutoRefresh();

      // Aunque ahora no mostramos el balance aquí, puede servir luego
      Provider.of<WalletProvider>(context, listen: false).fetchWallet();
    });
  }

  @override
  void dispose() {
    Provider.of<MarketProvider>(context, listen: false).stopAutoRefresh();
    _bobController.dispose();
    super.dispose();
  }

  double? _bobPerTrueCoin(MarketProvider provider) {
    final rate = provider.rate;
    if (rate == null) return null;
    return rate.price / _trueCoinsPerDollar;
  }

  double? _trueCoinsToReceive(double? bob, double? bobPerCoin) {
    if (bob == null || bob <= 0) return null;
    if (bobPerCoin == null || bobPerCoin == 0) return null;
    return bob / bobPerCoin;
  }

  void _onBobChanged(String value) {
    final normalized = value.replaceAll(',', '.');
    setState(() {
      _bobAmount = double.tryParse(normalized);
    });
  }

  String _mapDioError(DioException error) {
    if (error.response?.statusCode == 403) {
      return 'El servidor rechazó la operación (403). Es posible que tu cuenta no tenga permisos aún.';
    }
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return error.message ?? 'Ocurrió un error al crear la orden P2P.';
  }

  Future<void> _handleConfirm(BuildContext context) async {
    final market = context.read<MarketProvider>();
    final p2pProvider = context.read<P2POrderProvider>();

    final bobPerCoin = _bobPerTrueCoin(market);
    final trueCoins = _trueCoinsToReceive(_bobAmount, bobPerCoin);

    if (_bobAmount == null ||
        _bobAmount! <= 0 ||
        trueCoins == null ||
        trueCoins <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido en bolivianos.')),
      );
      return;
    }

    // bobPerCoin = BOB por 1 TrueCoin
    // rate = TrueCoins por 1 BOB = 1 / bobPerCoin
    final rate = bobPerCoin != null && bobPerCoin > 0 ? 1 / bobPerCoin : 0;
    if (rate == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la tasa de cambio.')),
      );
      return;
    }

    final p2pType = _isDeposit ? P2POrderType.deposit : P2POrderType.withdraw;

    final request = P2POrderCreateRequest(
      type: p2pType,
      amountBob: _bobAmount!.toDouble(),
      amountTrueCoins: trueCoins.toDouble(),
      rate: rate.toDouble(),
      paymentMethod: 'Pago manual (acordar con la contraparte)',
    );

    try {
      final createdOrder = await p2pProvider.createOrder(request);

      if (!mounted) return;
      _bobController.clear();
      setState(() {
        _bobAmount = null;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => P2POrderDetailScreen(orderId: createdOrder.id),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapDioError(error))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo crear la orden P2P. Intenta de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isDeposit
        ? 'Recargar TrueCoins (P2P)'
        : 'Retirar TrueCoins (P2P)';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Consumer3<MarketProvider, WalletProvider, P2POrderProvider>(
        builder: (context, marketProvider, walletProvider, p2pProvider, child) {
          final bobPerCoin = _bobPerTrueCoin(marketProvider);
          final trueCoins = _trueCoinsToReceive(_bobAmount, bobPerCoin);
          final isWide = MediaQuery.of(context).size.width > 900;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RateHeader(
                  isLoading: marketProvider.isLoading,
                  bobPerCoin: bobPerCoin,
                  onRefresh: () => marketProvider.fetchRate(),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _TopUpForm(
                                bobController: _bobController,
                                bobAmount: _bobAmount,
                                trueCoins: trueCoins,
                                onChanged: _onBobChanged,
                                isDeposit: _isDeposit,
                              ),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 320,
                              child: _ConfirmCard(
                                isLoading: marketProvider.isLoading,
                                isProcessing: p2pProvider.isCreating,
                                trueCoins: trueCoins,
                                bobAmount: _bobAmount,
                                isDeposit: _isDeposit,
                                onConfirm: () => _handleConfirm(context),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          children: [
                            _TopUpForm(
                              bobController: _bobController,
                              bobAmount: _bobAmount,
                              trueCoins: trueCoins,
                              onChanged: _onBobChanged,
                              isDeposit: _isDeposit,
                            ),
                            const SizedBox(height: 24),
                            _ConfirmCard(
                              isLoading: marketProvider.isLoading,
                              isProcessing: p2pProvider.isCreating,
                              trueCoins: trueCoins,
                              bobAmount: _bobAmount,
                              isDeposit: _isDeposit,
                              onConfirm: () => _handleConfirm(context),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RateHeader extends StatelessWidget {
  final bool isLoading;
  final double? bobPerCoin;
  final Future<void> Function() onRefresh;

  const _RateHeader({
    required this.isLoading,
    required this.bobPerCoin,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final tenCoinText = bobPerCoin != null
        ? '10 TrueCoins ≈ Bs ${(bobPerCoin! * _WalletScreenState._trueCoinsPerDollar).toStringAsFixed(2)}'
        : 'Obteniendo tasa...';
    final oneCoinText = bobPerCoin != null
        ? '1 TrueCoin ≈ Bs ${bobPerCoin!.toStringAsFixed(2)}'
        : '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const Icon(Icons.swap_vert, size: 32, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tasa de conversión TrueCoin / BOB',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tenCoinText,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (oneCoinText.isNotEmpty)
                    Text(
                      oneCoinText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: isLoading ? null : onRefresh,
              icon: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopUpForm extends StatelessWidget {
  final TextEditingController bobController;
  final double? bobAmount;
  final double? trueCoins;
  final ValueChanged<String> onChanged;
  final bool isDeposit;

  const _TopUpForm({
    required this.bobController,
    required this.bobAmount,
    required this.trueCoins,
    required this.onChanged,
    required this.isDeposit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeposit
                      ? '¿Cuánto deseas ingresar?'
                      : '¿Cuánto deseas retirar?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bobController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monto en Bolivianos',
                    prefixIcon: const Icon(Icons.currency_exchange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: onChanged,
                ),
                const SizedBox(height: 16),
                const Text(
                  'El monto se convertirá automáticamente a TrueCoins usando la tasa actual.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDeposit ? 'Ingresarás (BOB)' : 'Recibirás (BOB)',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      bobAmount != null
                          ? 'Bs ${bobAmount!.toStringAsFixed(2)}'
                          : '—',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDeposit
                          ? 'Recibirás (TrueCoins)'
                          : 'Venderás (TrueCoins)',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      trueCoins != null
                          ? '${trueCoins!.toStringAsFixed(2)} TC'
                          : '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  final bool isLoading;
  final bool isProcessing;
  final double? trueCoins;
  final double? bobAmount;
  final bool isDeposit;
  final VoidCallback onConfirm;

  const _ConfirmCard({
    required this.isLoading,
    required this.isProcessing,
    required this.trueCoins,
    required this.bobAmount,
    required this.isDeposit,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final canConfirm =
        !isLoading && !isProcessing && trueCoins != null && trueCoins! > 0;

    String formatBob(double? value) =>
        value != null ? 'Bs ${value.toStringAsFixed(2)}' : '—';
    String formatCoins(double? value) =>
        value != null ? '${value.toStringAsFixed(2)} TrueCoins' : '—';

    final actionDescription = isDeposit
        ? 'pagar ${formatBob(bobAmount)} y recibir ${formatCoins(trueCoins)}'
        : 'vender ${formatCoins(trueCoins)} y recibir ${formatBob(bobAmount)}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Confirmación',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Vas a crear una orden P2P para $actionDescription. '
              'Otro usuario deberá tomarla y coordinar el intercambio.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: canConfirm ? onConfirm : null,
              icon: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                isProcessing ? 'Creando orden...' : 'Crear orden P2P',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
