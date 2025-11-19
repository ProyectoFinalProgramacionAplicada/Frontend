import 'package:dio/dio.dart';
import 'api_client.dart';
import '../dto/wallet/wallet_balance_dto.dart';
import '../dto/wallet/wallet_adjust_request.dart';

class WalletService {
  final Dio _dio = ApiClient().dio;

  Future<WalletBalanceDto> getMyWallet() async {
    final response = await _dio.get('/Wallet/me');
    return WalletBalanceDto.fromJson(response.data);
  }

  Future<void> adjustBalance(WalletAdjustRequest request) async {
    await _dio.post('/Wallet/adjust', data: request.toJson());
  }
}
