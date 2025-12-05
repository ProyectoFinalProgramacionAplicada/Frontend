// lib/providers/trade_provider.dart
import 'dart:async'; // <--- NECESARIO PARA EL TIMER
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../core/utils/app_constants.dart';
import '../dto/trade/trade_dto.dart';
import '../dto/trade/trade_create_dto.dart';
import '../dto/trade/trade_update_status_dto.dart';
import '../dto/trade/trade_message_create_dto.dart';
import '../dto/trade/trade_message_dto.dart';
import '../services/trade_service.dart';
import '../services/listing_service.dart';
import '../dto/trade/trade_counter_offer_dto.dart';

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

  // --- VARIABLES SIGNALR ---
  HubConnection? _hubConnection;
  bool get isLiveConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  // --- VARIABLES PARA "ESCRIBIENDO..." (NUEVO) ---
  bool _isOtherUserTyping = false;
  bool get isOtherUserTyping => _isOtherUserTyping;

  Timer? _typingClearTimer;
  DateTime? _lastTypingSentTime;

  void setCurrentTrade(TradeDto? trade) {
    _currentTrade = trade;
    notifyListeners();
  }

  // Pending sets para evitar doble envío
  final Set<int> _pendingCreates = {};
  final Set<int> _pendingSends = {};
  final Set<int> _pendingCounterOffers = {};

  // --- Helpers ---
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
    if (_pendingCreates.contains(dto.targetListingId)) {
      throw Exception('Oferta en proceso.');
    }
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
    } catch (e) {
      // NO convierta el error aquí. Déjelo pasar para que la UI lo analice.
      rethrow; 
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

  // --- Counter offer ---
  Future<void> sendCounterOffer(
    int tradeId, {
    int? offeredListingId,
    double? offeredTrueCoins,
    double? requestedTrueCoins,
    String? message,
    int? targetListingId,
  }) async {
    if (_pendingCounterOffers.contains(tradeId)) {
      throw Exception('Contraoferta en proceso...');
    }
    _pendingCounterOffers.add(tradeId);
    notifyListeners();

    try {
      final dto = TradeCounterOfferDto(
        targetListingId: targetListingId,
        offeredListingId: offeredListingId,
        offeredTrueCoins: offeredTrueCoins,
        requestedTrueCoins: requestedTrueCoins,
        message: message,
      );
      await _service.counterOfferTrade(tradeId, dto);
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

  // --- Mensajería integrada ---
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

      // Después de enviar, recargar mensajes desde la API
      await fetchMessages(tradeId);
    } catch (e) {
      rethrow;
    } finally {
      _pendingSends.remove(tradeId);
      notifyListeners();
    }
  }

  // =================================================================
  // === MÉTODOS SIGNALR ===
  // =================================================================

  Future<void> connectToChatHub() async {
    if (_hubConnection != null &&
        _hubConnection!.state == HubConnectionState.Connected)
      return;

    final baseUrl = AppConstants.apiBaseUrl.replaceAll('/api', '');
    final hubUrl = '$baseUrl/chatHub';

    print("🔌 Conectando a SignalR: $hubUrl");

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .withAutomaticReconnect()
        .build();

    // Escuchamos los eventos
    _hubConnection?.on("ReceiveMessage", _handleNewMessage);
    _hubConnection?.on("UserTyping", _handleUserTyping); // <--- NUEVO EVENTO

    try {
      await _hubConnection?.start();
      print("✅ SignalR Conectado!");
    } catch (e) {
      print("❌ Error conectando SignalR: $e");
    }
  }

  // Manejar mensaje entrante
  void _handleNewMessage(List<dynamic>? args) {
    if (args != null && args.isNotEmpty) {
      // Al llegar un mensaje, dejamos de mostrar "Escribiendo..." inmediatamente
      _isOtherUserTyping = false;

      final msgMap = args[0] as Map<String, dynamic>;
      final incomingTradeId = msgMap['tradeId']; // ID del backend

      final newMessage = TradeMessageDto(
        id: msgMap['id'],
        senderUserId: msgMap['senderUserId'],
        text: msgMap['text'],
        createdAt: DateTime.parse(msgMap['createdAt']),
        senderUserName: msgMap['senderUserName'],
      );

      // Si tenemos la lista cargada, actualizamos
      if (incomingTradeId != null &&
          _messagesByTrade.containsKey(incomingTradeId)) {
        final currentMsgs = _messagesByTrade[incomingTradeId] ?? [];
        if (!currentMsgs.any((m) => m.id == newMessage.id)) {
          _messagesByTrade[incomingTradeId] = List<TradeMessageDto>.from(
            currentMsgs,
          )..add(newMessage);
          notifyListeners();
        }
      }
    }
  }

  // --- LÓGICA DE ESCRIBIENDO ---

  // 1. Recibir aviso del servidor
  void _handleUserTyping(List<dynamic>? args) {
    _isOtherUserTyping = true;
    notifyListeners();

    // Reset timer: si no llega otro aviso en 3s, se quita
    _typingClearTimer?.cancel();
    _typingClearTimer = Timer(const Duration(seconds: 3), () {
      _isOtherUserTyping = false;
      notifyListeners();
    });
  }

  // 2. Enviar mi estado (Throttle 2s)
  Future<void> notifyImTyping(int tradeId, String myName) async {
    if (!isLiveConnected) return;

    final now = DateTime.now();
    if (_lastTypingSentTime != null &&
        now.difference(_lastTypingSentTime!) < const Duration(seconds: 2)) {
      return;
    }

    _lastTypingSentTime = now;
    try {
      await _hubConnection?.invoke(
        "SendTyping",
        args: [tradeId.toString(), myName],
      );
    } catch (e) {
      print("Error enviando typing: $e");
    }
  }

  // Unirse al grupo
  Future<void> joinTradeChat(int tradeId) async {
    await connectToChatHub();

    // Agrega esta línea para inicializar la lista de mensajes vacía si no existe
    if (!_messagesByTrade.containsKey(tradeId)) {
      _messagesByTrade[tradeId] = [];
    }

    if (isLiveConnected) {
      await _hubConnection?.invoke(
        "JoinTradeGroup",
        args: [tradeId.toString()],
      );
      print("🔊 Unido al grupo del trade $tradeId");
    }
  }

  // Salir del grupo
  Future<void> leaveTradeChat(int tradeId) async {
    if (isLiveConnected) {
      await _hubConnection?.invoke(
        "LeaveTradeGroup",
        args: [tradeId.toString()],
      );
      print("🔇 Salido del grupo del trade $tradeId");

      // Limpiar estado al salir
      _isOtherUserTyping = false;
      _typingClearTimer?.cancel();
    }
  }
}
