// lib/providers/trade_provider.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../dto/trade/trade_dto.dart';
import '../dto/trade/trade_create_dto.dart';
// ignore: unused_import
import '../dto/trade/trade_update_dto.dart';
import '../dto/trade/trade_update_status_dto.dart';
import '../dto/trade/trade_message_create_dto.dart';
import 'package:truekapp/dto/trade/trade_message_dto.dart';
import '../services/trade_service.dart';
import '../services/listing_service.dart';
import '../dto/listing/listing_dto.dart';

class TradeProvider extends ChangeNotifier {
  final TradeService _service = TradeService();

  List<TradeDto> myTrades = [];
  bool isLoading = false;

  // Mensajes por trade
  final Map<int, List<TradeMessageDto>> _messagesByTrade = {};
  bool _isLoadingMessages = false;
  String? _messagesError;

  // Cache para títulos de listings (evita llamadas repetidas)
  final Map<int, String?> _listingTitleCache = {};

  /// Obtiene (y cachea) el título de un listing por su id.
  /// Retorna null si falla la petición.
  Future<String?> fetchListingTitle(int listingId) async {
    if (_listingTitleCache.containsKey(listingId)) {
      return _listingTitleCache[listingId];
    }

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

  /// Devuelve el título cacheado si existe (no hace una petición)
  String? getCachedListingTitle(int listingId) => _listingTitleCache[listingId];

  /// Indica si ya hay una creación de oferta en curso para ese listing
  bool isCreatePendingFor(int listingId) => _pendingCreates?.contains(listingId) ?? false;

  /// Indica si ya hay un envío de mensaje en curso para ese trade
  bool isSendPendingFor(int tradeId) => _pendingSends?.contains(tradeId) ?? false;

  Future<void> fetchMyTrades() async {
    isLoading = true;
    notifyListeners();

    try {
      final fetched = await _service.getMyTrades();
      // Dedupe trades by id (preserve order)
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

  // Obtiene mensajes de un trade y los guarda en memoria
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
      // Dedupe messages by id when available, otherwise by message+createdAt
      final seen = <String>{};
      final deduped = <TradeMessageDto>[];
      for (final m in messages) {
        final key = (m.id != null)
            ? 'id:\${m.id}'
            : 'm:\${m.message ?? ''}|t:\${m.createdAt?.toIso8601String() ?? ''}';
        if (!seen.contains(key)) {
          seen.add(key);
          deduped.add(m);
        }
      }
      _messagesByTrade[tradeId] = deduped;
    } catch (e) {
      _messagesError = _formatError(e);
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> createTrade(TradeCreateDto dto) async {
    // Prevent multiple simultaneous create calls for the same target listing
    _pendingCreates ??= <int>{};
    final listingId = dto.targetListingId;
    if (_pendingCreates!.contains(listingId)) {
      throw Exception('Ya hay una oferta en proceso para este producto.');
    }
    _pendingCreates!.add(listingId);
    try {
      await _service.createTrade(dto);
      await fetchMyTrades();
    } catch (e) {
      // If server returned 500 while creating but may have persisted the trade,
      // attempt to refresh trades and check whether a trade for this listing exists.
      if (e is DioError && e.response?.statusCode == 500) {
        try {
          await fetchMyTrades();
          final exists = myTrades.any((t) => t.targetListingId == listingId);
          if (exists) {
            // Treat as success when backend likely created the trade but failed
            // to serialize response (workaround for server-side serialization bug).
            return;
          }
        } catch (_) {
          // fallthrough to rethrow original error below
        }
      }

      throw Exception(_formatError(e));
    } finally {
      _pendingCreates!.remove(listingId);
    }
  }

  Future<void> acceptTrade(int id) async {
    await _service.acceptTrade(id);
    await fetchMyTrades();
  }

  Future<void> updateTradeStatus(int id, TradeUpdateStatusDto dto) async {
    await _service.updateTradeStatus(id, dto);
    await fetchMyTrades();
  }

  Future<void> sendMessage(int tradeId, TradeMessageCreateDto dto) async {
    await _service.sendMessage(tradeId, dto);
  }

  /// Envía un mensaje y refresca la lista de mensajes del trade
  Future<void> sendMessageAndRefresh(int tradeId, String text) async {
    // Prevent duplicate rapid sends for the same trade
    _pendingSends ??= <int>{};
    if (_pendingSends!.contains(tradeId)) {
      throw Exception('Envío en proceso, por favor espera...');
    }
    _pendingSends!.add(tradeId);
    try {
      final dto = TradeMessageCreateDto(message: text);
      await sendMessage(tradeId, dto);
      await fetchMessages(tradeId);
    } catch (e) {
      throw Exception(_formatError(e));
    } finally {
      _pendingSends!.remove(tradeId);
    }
  }

  // Internal helpers
  Set<int>? _pendingCreates;
  Set<int>? _pendingSends;

  String _formatError(Object e) {
    if (e is DioError) {
      final r = e.response;
      final status = r?.statusCode;
      final data = r?.data;
      return 'DioException [status: $status]: ${data ?? e.message}';
    }
    return e.toString();
  }
}
