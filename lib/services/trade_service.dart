import 'package:dio/dio.dart';
import 'dart:convert';
import 'api_client.dart';
import '../dto/trade/trade_create_dto.dart';
import '../dto/trade/trade_dto.dart';
import '../dto/trade/trade_update_dto.dart';
import '../dto/trade/trade_update_status_dto.dart';
import '../dto/trade/trade_message_create_dto.dart';
import '../dto/trade/trade_counter_offer_dto.dart';
import 'package:truekapp/dto/trade/trade_message_dto.dart';

class TradeService {
  final Dio _dio = ApiClient().dio;

  Future<void> createTrade(TradeCreateDto dto) async {
    await _dio.post('/Trades', data: dto.toJson());
  }

  Future<void> updateTrade(int id, TradeUpdateDto dto) async {
    await _dio.put('/Trades/$id', data: dto.toJson());
  }

  Future<void> counterOfferTrade(int id, TradeCounterOfferDto dto) async {
    await _dio.patch('/Trades/$id/counter', data: dto.toJson());
  }

  Future<void> updateTradeStatus(int id, TradeUpdateStatusDto dto) async {
    await _dio.patch('/Trades/$id/status', data: dto.toJson());
  }

  Future<void> acceptTrade(int id) async {
    await _dio.patch('/Trades/$id/accept');
  }

  Future<List<TradeDto>> getMyTrades() async {
    final response = await _dio.get('/Trades/my');
    return (response.data as List).map((e) => TradeDto.fromJson(e)).toList();
  }

  /// Recupera el historial de mensajes para un trade específico.
  Future<List<TradeMessageDto>> getMessages(int tradeId) async {
    try {
      final response = await _dio.get('/Trades/$tradeId/messages');
      final data = response.data;

      // The backend should return a JSON array, but different wrappers are
      // possible (single object, object with 'data' or 'items', etc.). Be
      // tolerant and normalize to a List<Map> when possible.
      List<Map<String, dynamic>> normalize(dynamic raw) {
        if (raw == null) return [];
        if (raw is List) {
          return raw.map((e) => e as Map<String, dynamic>).toList();
        }
        if (raw is Map<String, dynamic>) {
          // Common wrappers
          if (raw['data'] is List)
            return (raw['data'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          if (raw['items'] is List)
            return (raw['items'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          if (raw['messages'] is List)
            return (raw['messages'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          // If it's a single object representing a message, return single-element list
          return [raw];
        }
        return [];
      }

      final list = normalize(data);
      return list.map((e) => TradeMessageDto.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error obteniendo mensajes del trade $tradeId: $e');
    }
  }

  Future<void> sendMessage(int tradeId, TradeMessageCreateDto dto) async {
    // The API expects a JSON string in the body (e.g. "Hola...").
    // Ensure we send a valid JSON payload by encoding the Dart String.
    final body = jsonEncode(dto.message);
    await _dio.post(
      '/Trades/$tradeId/messages',
      data: body,
      options: Options(headers: {"Content-Type": "application/json"}),
    );
  }

  Future<void> completeTrade(int tradeId) async {
    await _dio.post('/Trades/$tradeId/complete');
  }
}
