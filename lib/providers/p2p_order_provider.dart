import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dto/p2p/p2p_order_create_request.dart';
import '../dto/p2p/p2p_order_dto.dart';

class P2POrderProvider with ChangeNotifier {
  final Dio _dio;

  P2POrderProvider(this._dio);

  bool isCreating = false;
  bool isLoadingOrderBook = false;
  List<P2POrderDto> orderBook = [];
  final Map<int, P2POrderDto> _trackedOrders = {};
  static const _trackedPrefsKey = 'p2p_tracked_orders';
  bool _hasRestoredTracked = false;

  int? _takingOrderId;
  int? get takingOrderId => _takingOrderId;
  bool get isTakingOrder => _takingOrderId != null;
  Map<int, P2POrderDto> get trackedOrders => Map.unmodifiable(_trackedOrders);

  void cacheTrackedOrder(P2POrderDto order, {bool persist = true}) {
    final shouldRemove =
        order.status >= P2POrderStatus.released ||
        order.status == P2POrderStatus.cancelled ||
        order.status == P2POrderStatus.disputed;

    if (shouldRemove) {
      final removed = _trackedOrders.remove(order.id) != null;
      if (persist) _schedulePersistTrackedIds();
      if (removed) notifyListeners();
      return;
    }

    final existing = _trackedOrders[order.id];
    if (existing == null || _hasMeaningfulChange(existing, order)) {
      _trackedOrders[order.id] = order;
      if (persist) _schedulePersistTrackedIds();
      notifyListeners();
    }
  }

  bool _hasMeaningfulChange(P2POrderDto previous, P2POrderDto current) {
    return previous.status != current.status ||
        previous.counterpartyUserId != current.counterpartyUserId ||
        previous.amountBob != current.amountBob ||
        previous.amountTrueCoins != current.amountTrueCoins;
  }

  Future<P2POrderDto> createOrder(P2POrderCreateRequest request) async {
    try {
      isCreating = true;
      notifyListeners();

      final response = await _dio.post('P2POrders', data: request.toJson());
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final order = P2POrderDto.fromJson(data);
        cacheTrackedOrder(order);
        return order;
      }

      if (data is num) {
        final order = await _fetchOrderById(data.toInt());
        cacheTrackedOrder(order);
        return order;
      }

      throw Exception('No se pudo obtener la orden creada.');
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }

  Future<P2POrderDto> _fetchOrderById(int id) async {
    final response = await _dio.get('P2POrders/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return P2POrderDto.fromJson(data);
    }
    throw Exception('No se pudo cargar la orden #$id');
  }

  Future<void> fetchOrderBook() async {
    try {
      isLoadingOrderBook = true;
      notifyListeners();

      final response = await _dio.get('P2POrders/book');
      final publicOrders = _mapResponseToOrders(response.data);

      List<P2POrderDto> personalOrders = [];
      try {
        final mineResponse = await _dio.get('P2POrders/mine');
        personalOrders = _mapResponseToOrders(mineResponse.data);
      } on DioException catch (error) {
        if (kDebugMode) {
          debugPrint('No se pudieron cargar las órdenes del usuario: $error');
        }
      }

      if (personalOrders.isNotEmpty) {
        for (final order in personalOrders) {
          cacheTrackedOrder(order);
        }
      }

      final combined = {for (final order in publicOrders) order.id: order};

      for (final order in personalOrders) {
        combined[order.id] = order;
      }

      orderBook = combined.values.toList();
    } on DioException {
      rethrow;
    } finally {
      isLoadingOrderBook = false;
      notifyListeners();
    }
  }

  List<P2POrderDto> _mapResponseToOrders(dynamic data) {
    if (data is List) {
      return data
          .map(
            (item) => item is Map<String, dynamic>
                ? P2POrderDto.fromJson(item)
                : null,
          )
          .whereType<P2POrderDto>()
          .toList();
    }
    return [];
  }

  Future<P2POrderDto> takeOrder(int orderId) async {
    try {
      _takingOrderId = orderId;
      notifyListeners();

      await _dio.patch('P2POrders/$orderId/take');
      final updated = await _fetchOrderById(orderId);
      cacheTrackedOrder(updated);
      await fetchOrderBook();
      return updated;
    } on DioException {
      rethrow;
    } finally {
      _takingOrderId = null;
      notifyListeners();
    }
  }

  List<P2POrderDto> getOrdersForUser(int? userId) {
    if (userId == null) return List.unmodifiable(orderBook);

    final Map<int, P2POrderDto> combined = {
      for (final order in orderBook) order.id: order,
    };

    for (final entry in _trackedOrders.values) {
      final involvesUser =
          entry.creatorUserId == userId ||
          (entry.counterpartyUserId != null &&
              entry.counterpartyUserId == userId);
      if (!involvesUser || !_shouldDisplayToParticipant(entry.status)) continue;

      combined[entry.id] = entry;
    }

    return List.unmodifiable(combined.values);
  }

  Future<void> restoreTrackedOrders() async {
    if (_hasRestoredTracked) return;
    _hasRestoredTracked = true;
    final prefs = await SharedPreferences.getInstance();
    final idStrings = prefs.getStringList(_trackedPrefsKey) ?? [];
    for (final idStr in idStrings) {
      final id = int.tryParse(idStr);
      if (id == null) continue;
      try {
        final order = await _fetchOrderById(id);
        cacheTrackedOrder(order, persist: false);
      } catch (_) {
        _trackedOrders.remove(id);
      }
    }
    _schedulePersistTrackedIds();
  }

  Future<void> refreshTrackedOrders() async {
    await restoreTrackedOrders();
    final ids = _trackedOrders.keys.toList();
    for (final id in ids) {
      try {
        final order = await _fetchOrderById(id);
        cacheTrackedOrder(order);
      } catch (_) {
        final removed = _trackedOrders.remove(id) != null;
        if (removed) {
          _schedulePersistTrackedIds();
          notifyListeners();
        }
      }
    }
  }

  void _schedulePersistTrackedIds() {
    SharedPreferences.getInstance()
        .then((prefs) {
          final ids = _trackedOrders.keys.map((e) => e.toString()).toList();
          prefs.setStringList(_trackedPrefsKey, ids);
        })
        .catchError((_) {
          // Ignore persistence errors silently.
        });
  }

  bool _shouldDisplayToParticipant(int status) {
    return status == P2POrderStatus.pending ||
        status == P2POrderStatus.matched ||
        status == P2POrderStatus.paid;
  }
}
