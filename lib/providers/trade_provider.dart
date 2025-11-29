// lib/providers/trade_provider.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../dto/trade/trade_dto.dart';
import '../dto/trade/trade_create_dto.dart';
import '../dto/trade/trade_update_dto.dart';
import '../dto/trade/trade_update_status_dto.dart';
import '../dto/trade/trade_message_create_dto.dart';
import '../dto/trade/trade_message_dto.dart';
import '../services/trade_service.dart';
import '../services/listing_service.dart';

class TradeProvider extends ChangeNotifier {
  final TradeService _service = TradeService();

  List<TradeDto> myTrades = [];
  bool isLoading = false;

  // Mensajes por trade
  final Map<int, List<TradeMessageDto>> _messagesByTrade = {};
  bool _isLoadingMessages = false;
  String? _messagesError;

  // Cache para títulos
  final Map<int, String?> _listingTitleCache = {};

  // Trade seleccionado actualmente
  TradeDto? _currentTrade;
  TradeDto? get currentTrade => _currentTrade;

  void setCurrentTrade(TradeDto? trade) {
    _currentTrade = trade;
    notifyListeners();
  }

  // Pending sets para evitar doble envío (creación/envío de mensajes/contraoferta)
  final Set<int> _pendingCreates = {};
  final Set<int> _pendingSends = {};
  final Set<int> _pendingCounterOffers = {};

  // --- Helpers ---
  Future<String?> fetchListingTitle(int listingId) async {
    if (_listingTitleCache.containsKey(listingId))
      return _listingTitleCache[listingId];
    try {
      final listing = await ListingService().getListingById(listingId);
      final title = listing.title.isNotEmpty
          ? listing.title
          : (listing.ownerName ?? 'Trueque #$listingId');
      _listingTitleCache[listingId] = title;
      return title;
    } catch (e) {
      _listingTitleCache[listingId] = null;
      return null;
    }
  }

  String? getCachedListingTitle(int listingId) => _listingTitleCache[listingId];
  bool isCreatePendingFor(int listingId) => _pendingCreates.contains(listingId);
  bool isSendPendingFor(int tradeId) => _pendingSends.contains(tradeId);
  bool isCounterPendingFor(int tradeId) =>
      _pendingCounterOffers.contains(tradeId);

  // --- Trades CRUD / Flow ---
  Future<void> fetchMyTrades() async {
    isLoading = true;
    notifyListeners();
    try {
      final fetched = await _service.getMyTrades();
      final seen = <int>{};
      final deduped = <TradeDto>[];
      for (final t in fetched) {
        if (!seen.contains(t.id)) {
          seen.add(t.id);
          deduped.add(t);
        }
      }
      myTrades = deduped;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTrade(TradeCreateDto dto) async {
    if (_pendingCreates.contains(dto.targetListingId))
      throw Exception('Oferta en proceso.');
    _pendingCreates.add(dto.targetListingId);
    notifyListeners();
    try {
      await _service.createTrade(dto);
      await fetchMyTrades();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 500) {
        await fetchMyTrades();
        return;
      }
      rethrow;
    } finally {
      _pendingCreates.remove(dto.targetListingId);
      notifyListeners();
    }
  }

  Future<void> acceptTrade(int id) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.acceptTrade(id);
      await fetchMyTrades();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTradeStatus(int id, TradeUpdateStatusDto dto) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.updateTradeStatus(id, dto);
      await fetchMyTrades();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeTrade(int tradeId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.completeTrade(tradeId);
      await fetchMyTrades();
      if (_currentTrade != null && _currentTrade!.id == tradeId) {
        _currentTrade = myTrades.firstWhere(
          (t) => t.id == tradeId,
          orElse: () => _currentTrade!,
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Counter offer (contraoferta) ---
  /// Actualiza un trade existente (contraoferta). Usa TradeUpdateDto.
  Future<void> sendCounterOffer(
    int tradeId, {
    int? offeredListingId,
    double? offeredTrueCoins,
    double? requestedTrueCoins,
    String? message,
    int? requestedOtherListingId,
  }) async {
    if (_pendingCounterOffers.contains(tradeId))
      throw Exception('Contraoferta en proceso...');
    _pendingCounterOffers.add(tradeId);
    notifyListeners();

    try {
      final dto = TradeUpdateDto(
        offeredListingId: offeredListingId,
        offeredTrueCoins: offeredTrueCoins,
        requestedTrueCoins: requestedTrueCoins,
        message: message,
        requestedOtherListingId: requestedOtherListingId,
      );
      await _service.updateTrade(tradeId, dto);
      await fetchMyTrades();
      if (_currentTrade?.id == tradeId) {
        _currentTrade = myTrades.firstWhere(
          (t) => t.id == tradeId,
          orElse: () => _currentTrade!,
        );
      }
    } catch (e) {
      rethrow;
    } finally {
      _pendingCounterOffers.remove(tradeId);
      notifyListeners();
    }
  }

  // --- Mensajería integrada (chat ya la tienes, esto refresca mensajes) ---
  List<TradeMessageDto> getMessagesForTrade(int tradeId) =>
      _messagesByTrade[tradeId] ?? [];
  bool get isLoadingMessages => _isLoadingMessages;
  String? get messagesError => _messagesError;

  Future<void> fetchMessages(int tradeId) async {
    _isLoadingMessages = true;
    _messagesError = null;
    notifyListeners();
    try {
      final messages = await _service.getMessages(tradeId);
      messages.sort((a, b) {
        final ta = a.createdAt ?? DateTime(1970);
        final tb = b.createdAt ?? DateTime(1970);
        return ta.compareTo(tb);
      });

      final seenIds = <int>{};
      final deduped = <TradeMessageDto>[];
      for (final m in messages) {
        if (m.id != null) {
          if (seenIds.contains(m.id)) continue;
          seenIds.add(m.id!);
          deduped.add(m);
        } else {
          deduped.add(m);
        }
      }
      _messagesByTrade[tradeId] = deduped;
    } catch (e) {
      _messagesError = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendMessageAndRefresh(int tradeId, String text) async {
    if (_pendingSends.contains(tradeId)) throw Exception('Envío en proceso...');
    _pendingSends.add(tradeId);
    notifyListeners();
    try {
      final dto = TradeMessageCreateDto(message: text);
      await _service.sendMessage(tradeId, dto);
      await fetchMessages(tradeId);
    } catch (e) {
      rethrow;
    } finally {
      _pendingSends.remove(tradeId);
      notifyListeners();
    }
  }
}
