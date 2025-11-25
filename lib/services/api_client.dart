// lib/services/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  late Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        // Usa la URL correcta de la API desplegada
        baseUrl: 'http://localhost:5129/api/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    // Add logging interceptor to help debugging request/response payloads
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
      ),
    );
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}
