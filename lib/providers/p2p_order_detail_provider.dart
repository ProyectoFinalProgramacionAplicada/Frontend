import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../dto/p2p/p2p_order_dto.dart';

class P2POrderDetailProvider with ChangeNotifier {
  final Dio _dio;

  P2POrderDetailProvider(this._dio);

  P2POrderDto? currentOrder;
  bool isLoading = false;
  bool isProcessing = false;

  Future<void> loadOrder(int id) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await _dio.get('/P2POrders/$id');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        currentOrder = P2POrderDto.fromJson(data);
      } else {
        throw Exception('No se pudo cargar la orden #$id');
      }
    } on DioException {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsPaid(int id) async {
    await _runAction(() async {
      await _dio.patch('/P2POrders/$id/paid');
      await loadOrder(id);
    });
  }

  Future<void> releaseOrder(int id) async {
    await _runAction(() async {
      await _dio.patch('/P2POrders/$id/release');
      await loadOrder(id);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      isProcessing = true;
      notifyListeners();
      await action();
    } on DioException {
      rethrow;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
