// lib/services/admin_service.dart
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../dto/admin/admin_metrics_dto.dart';

/// Servicio para obtener datos del panel de administración
/// Consume los endpoints reales del backend:
/// - GET /Admin/stats
/// - GET /Admin/users
/// - GET /Admin/trades
/// - GET /Admin/wallet-activity
class AdminService {
  final Dio _dio = ApiClient().dio;

  /// Obtiene las estadísticas agregadas del sistema
  /// Endpoint: GET /Admin/stats
  Future<AdminStatsDto> getStats() async {
    try {
      final response = await _dio.get('/Admin/stats');
      return AdminStatsDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return AdminStatsDto.empty();
      }
      throw Exception('Error al obtener estadísticas: ${e.message}');
    }
  }

  /// Obtiene la lista de todos los usuarios
  /// Endpoint: GET /Admin/users
  Future<List<AdminUserDto>> getUsers() async {
    try {
      final response = await _dio.get('/Admin/users');
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => AdminUserDto.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception('Error al obtener usuarios: ${e.message}');
    }
  }

  /// Obtiene la lista de todos los trades
  /// Endpoint: GET /Admin/trades
  Future<List<AdminTradeDto>> getTrades() async {
    try {
      final response = await _dio.get('/Admin/trades');
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => AdminTradeDto.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception('Error al obtener trades: ${e.message}');
    }
  }

  /// Obtiene la actividad de wallet (ajustes de TrueCoins)
  /// Endpoint: GET /Admin/wallet-activity
  Future<List<WalletActivityDto>> getWalletActivity() async {
    try {
      final response = await _dio.get('/Admin/wallet-activity');
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => WalletActivityDto.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception('Error al obtener actividad de wallet: ${e.message}');
    }
  }

  /// Obtiene un usuario específico por ID
  /// Endpoint: GET /Admin/users/{id}
  Future<AdminUserDto?> getUserById(int userId) async {
    try {
      final response = await _dio.get('/Admin/users/$userId');
      return AdminUserDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Error al obtener usuario: ${e.message}');
    }
  }
}
