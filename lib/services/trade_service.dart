import 'package:dio/dio.dart';
import 'dart:convert';
import 'api_client.dart';
import '../dto/trade/trade_create_dto.dart';
import '../dto/trade/trade_dto.dart';
import '../dto/trade/trade_update_dto.dart';
import '../dto/trade/trade_update_status_dto.dart';
import '../dto/trade/trade_message_create_dto.dart';
import 'package:truekapp/dto/trade/trade_message_dto.dart';

class TradeService {
  final Dio _dio = ApiClient().dio;

  Future<void> createTrade(TradeCreateDto dto) async {
    await _dio.post('/Trades', data: dto.toJson());
  }

  Future<void> updateTrade(int id, TradeUpdateDto dto) async {
    await _dio.put('/Trades/$id', data: dto.toJson());
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
      final data = response.data as List;
      return data
          .map((e) => TradeMessageDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo mensajes del trade $tradeId: $e');
    }
  }

  Future<void> sendMessage(int tradeId, TradeMessageCreateDto dto) async {
    // The API expects a JSON string in the body (e.g. "Hola...").
    // Ensure we send a valid JSON payload by encoding the Dart String.
    final body = jsonEncode(dto.message);
    await _dio.post('/Trades/$tradeId/messages',
        data: body,
        options: Options(headers: {"Content-Type": "application/json"}));
  }

  Future<void> completeTrade(int tradeId) async {
  await _dio.post('/Trades/$tradeId/complete');
}
}
