// lib/providers/wallet_provider.dart
import 'package:flutter/material.dart';
import '../dto/wallet/wallet_adjust_request.dart';
import '../dto/wallet/wallet_balance_dto.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _service = WalletService();

  WalletBalanceDto? wallet;
  bool isLoading = false;
  bool isAdjusting = false;

  Future<void> fetchWallet() async {
    isLoading = true;
    notifyListeners();

    try {
      wallet = await _service.getMyWallet();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adjustBalance(WalletAdjustRequest request) async {
    isAdjusting = true;
    notifyListeners();

    try {
      await _service.adjustBalance(request);
      await fetchWallet();
    } finally {
      isAdjusting = false;
      notifyListeners();
    }
  }
}
