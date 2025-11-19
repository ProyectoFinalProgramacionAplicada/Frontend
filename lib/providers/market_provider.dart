import 'dart:async';

import 'package:flutter/material.dart';
import '../dto/market/market_rate_dto.dart';
import '../services/market_service.dart';

class MarketProvider extends ChangeNotifier {
  final MarketService _service = MarketService();

  MarketRateDto? rate;
  bool isLoading = false;
  Timer? _autoRefreshTimer;

  Future<void> fetchRate({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      notifyListeners();
    }
    try {
      rate = await _service.getUsdBobRate();
    } finally {
      if (!silent) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  void startAutoRefresh({Duration interval = const Duration(minutes: 1)}) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer =
        Timer.periodic(interval, (_) => fetchRate(silent: true));
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
