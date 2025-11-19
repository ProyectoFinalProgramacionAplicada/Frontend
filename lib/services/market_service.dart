import 'package:dio/dio.dart';
import '../dto/market/market_rate_dto.dart';
import 'api_client.dart';

class MarketService {
  final Dio _dio = ApiClient().dio;

  Future<MarketRateDto> getUsdBobRate() async {
    final response = await _dio.get('/v1/market/usdt-bob');
    return MarketRateDto.fromJson(response.data);
  }
}
