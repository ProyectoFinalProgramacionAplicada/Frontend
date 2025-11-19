import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../dto/wallet/wallet_adjust_request.dart';

class WalletScreen extends StatefulWidget {
	const WalletScreen({super.key});

	@override
	State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
	final TextEditingController _bobController = TextEditingController();
	double? _bobAmount;

	static const double _trueCoinsPerDollar = 10; // 1 USD = 10 TrueCoins

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) {
			final market = Provider.of<MarketProvider>(context, listen: false);
			market.fetchRate();
			market.startAutoRefresh();
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
			return 'El servidor rechazó la recarga (403). Tu cuenta no tiene permisos para usar este endpoint. Contacta a soporte para habilitarlo.';
		}
		final data = error.response?.data;
		if (data is Map && data['message'] is String) {
			return data['message'] as String;
		}
		return error.message ?? 'Ocurrió un error al confirmar el pago.';
	}

	Future<void> _handleConfirm(BuildContext context) async {
		final market = context.read<MarketProvider>();
		final walletProvider = context.read<WalletProvider>();
		final auth = context.read<AuthProvider>();
		final bobPerCoin = _bobPerTrueCoin(market);
		final trueCoins = _trueCoinsToReceive(_bobAmount, bobPerCoin);
		if (trueCoins == null || trueCoins <= 0) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Ingresa un monto válido en bolivianos.')),
			);
			return;
		}

		final userId = auth.user?.id;
		if (userId == null) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('No se pudo identificar al usuario. Inicia sesión nuevamente.')),
			);
			return;
		}

		final request = WalletAdjustRequest(
			userId: userId,
			amount: trueCoins,
			reason: 'Recarga desde app',
		);

		try {
			await walletProvider.adjustBalance(request);
			if (!mounted) return;
			_bobController.clear();
			setState(() {
				_bobAmount = null;
			});
			final newBalance = walletProvider.wallet?.balance;
			final message = newBalance != null
					? 'Recarga exitosa. Nuevo balance: ${newBalance.toStringAsFixed(2)} TrueCoins.'
					: 'Recarga exitosa.';
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(message)),
			);
		} on DioException catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(_mapDioError(error))),
			);
		} catch (_) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('No se pudo confirmar el pago. Intenta de nuevo.'),
				),
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Recargar TrueCoins')),
			body: Consumer2<MarketProvider, WalletProvider>(
				builder: (context, marketProvider, walletProvider, child) {
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
															),
														),
														const SizedBox(width: 24),
														SizedBox(
															width: 320,
															child: _ConfirmCard(
																isLoading: marketProvider.isLoading,
																isProcessing: walletProvider.isAdjusting,
																trueCoins: trueCoins,
																bobAmount: _bobAmount,
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
														),
														const SizedBox(height: 24),
														_ConfirmCard(
															isLoading: marketProvider.isLoading,
															isProcessing: walletProvider.isAdjusting,
															trueCoins: trueCoins,
															bobAmount: _bobAmount,
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
									Text(tenCoinText,
											style: const TextStyle(fontSize: 14, color: Colors.grey)),
									if (oneCoinText.isNotEmpty)
										Text(oneCoinText,
												style:
														const TextStyle(fontSize: 12, color: Colors.grey)),
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
						)
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

	const _TopUpForm({
		required this.bobController,
		required this.bobAmount,
		required this.trueCoins,
		required this.onChanged,
	});

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Card(
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
					child: Padding(
						padding: const EdgeInsets.all(20.0),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text(
									'¿Cuánto deseas ingresar?',
									style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
										const Text('Ingresarás (BOB)',
												style: TextStyle(color: Colors.grey)),
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
										const Text('Recibirás (TrueCoins)',
												style: TextStyle(color: Colors.grey)),
										Text(
											trueCoins != null
													? '${trueCoins!.toStringAsFixed(2)} TC'
													: '—',
											style: const TextStyle(
													fontWeight: FontWeight.w700, color: AppColors.primary),
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
	final VoidCallback onConfirm;

	const _ConfirmCard({
		required this.isLoading,
		required this.isProcessing,
		required this.trueCoins,
		required this.bobAmount,
		required this.onConfirm,
	});

	@override
	Widget build(BuildContext context) {
		final canConfirm = !isLoading && !isProcessing && trueCoins != null && trueCoins! > 0;

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
							'Vas a pagar ${bobAmount != null ? 'Bs ${bobAmount!.toStringAsFixed(2)}' : '—'}'
							' y recibir ${trueCoins != null ? '${trueCoins!.toStringAsFixed(2)} TrueCoins' : '—'}.'
							' Continúa para confirmar el pago.',
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
							label: Text(isProcessing ? 'Procesando...' : 'Confirmar pago'),
							style: ElevatedButton.styleFrom(
								minimumSize: const Size(double.infinity, 50),
							),
						)
					],
				),
			),
		);
	}
}
