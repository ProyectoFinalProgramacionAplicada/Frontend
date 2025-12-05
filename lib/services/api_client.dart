// lib/services/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  late Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        // Backend en Azure (desplegado con LoginResponseDto)
        // IMPORTANTE: Si estás probando en emulador Android localmente, recuerda usar 'http://10.0.2.2:5084/api'
        // Si estás usando el backend ya publicado en Azure, deja esta URL:
        baseUrl: 'https://app-251203232643.azurewebsites.net/api',
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

  // --- MÉTODO PARA LA IA (ESTE ES EL QUE FALTABA) ---
  Future<String> enhanceText(String text) async {
    try {
      final response = await dio.post(
        '/Ai/enhance', // Ruta del endpoint en tu backend
        data: {'text': text},
      );
      // El backend devuelve: { "text": "texto mejorado" }
      return response.data['text'];
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }
}