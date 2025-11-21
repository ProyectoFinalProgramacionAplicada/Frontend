import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../dto/auth/user_login_dto.dart';
import '../dto/auth/user_register_dto.dart';
import '../dto/auth/token_dto.dart';
import '../dto/auth/user_info_dto.dart';
// AÑADIDO: El DTO para actualizar perfil
import '../dto/auth/user_update_dto.dart'; 

class ValidationException implements Exception {
  final Map<String, List<String>> errors;
  final String? message;
  ValidationException(this.errors, {this.message});

  @override
  String toString() {
    if (message != null && message!.isNotEmpty) return message!;
    final parts = <String>[];
    errors.forEach((k, v) => parts.add('$k: ${v.join(', ')}'));
    return parts.join(' | ');
  }
}

class AuthService {
  final Dio _dio = ApiClient().dio;

  Future<TokenDto> login(UserLoginDto dto) async {
    try {
      final response = await _dio.post('/Auth/login', data: dto.toJson());
      final data = response.data;
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is Map<String, dynamic>) return TokenDto.fromJson(parsed);
        } catch (_) {
          return TokenDto(token: data);
        }
      }
      if (data is Map<String, dynamic>) return TokenDto.fromJson(data);
      return TokenDto(token: data?.toString());
    } on DioException catch (e) {
      final resp = e.response;
      if (resp != null) {
        final status = resp.statusCode;
        final serverMessage = _extractMessageFromResponse(resp.data);
        if (status == 401) {
          throw Exception('Credenciales inválidas. ${serverMessage ?? ''}');
        }
        throw Exception(
          'Error en login (${status ?? '??'}). ${serverMessage ?? resp.statusMessage ?? ''}',
        );
      }
      rethrow;
    }
  }

  Future<void> register(UserRegisterDto dto) async {
    try {
      await _dio.post('/Auth/register', data: dto.toJson());
    } on DioException catch (e) {
      final resp = e.response;
      if (resp != null) {
        final body = resp.data;
        if (body is Map && body['errors'] != null && body['errors'] is Map) {
          final Map<String, List<String>> errors = {};
          final errs = body['errors'] as Map;
          errs.forEach((k, v) {
            if (v is List) {
              errors[k.toString()] = v.map((e) => e.toString()).toList();
            } else {
              errors[k.toString()] = [v.toString()];
            }
          });
          final serverMessage = _extractMessageFromResponse(body);
          throw ValidationException(errors, message: serverMessage);
        }

        final serverMessage = _extractMessageFromResponse(resp.data);
        throw Exception(
          'Registro fallido (${resp.statusCode}). ${serverMessage ?? resp.statusMessage ?? ''}',
        );
      }
      rethrow;
    }
  }

  Future<String> forgotPassword(String email) async {
    final candidates = [
      '/Auth/forgot-password',
      '/Auth/forgot',
      '/Auth/request-password-reset',
    ];
    for (final path in candidates) {
      try {
        final resp = await _dio.post(path, data: {'email': email});
        final msg =
            _extractMessageFromResponse(resp.data) ??
            'Solicitud enviada si el correo existe.';
        return msg;
      } on DioException catch (e) {
        final resp = e.response;
        if (resp != null) {
          if (resp.statusCode == 404) continue;
          final serverMessage = _extractMessageFromResponse(resp.data);
          throw Exception(
            'Error: ${resp.statusCode}. ${serverMessage ?? resp.statusMessage ?? ''}',
          );
        }
        rethrow;
      }
    }
    throw Exception(
      'Funcionalidad de restablecer contraseña no disponible en el servidor.',
    );
  }

  Future<UserInfoDto> getMe() async {
    final response = await _dio.get('/Auth/me');
    var data = response.data;
    if (data is String) {
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) return UserInfoDto.fromJson(parsed);
      } catch (_) {
        throw Exception('Unexpected response format from /Auth/me');
      }
    }
    if (data is Map<String, dynamic>) return UserInfoDto.fromJson(data);
    throw Exception('Unexpected response format from /Auth/me');
  }

  // --- NUEVO MÉTODO: updateProfile ---
  // Conecta con UsersController
  Future<bool> updateProfile(UserUpdateDto dto) async {
    try {
      // IMPORTANTE: La ruta es /Users/me porque el backend lo definimos en UsersController
      final response = await _dio.put('/Users/me', data: dto.toJson());
      
      // Si el backend devuelve 200 OK, todo salió bien
      return response.statusCode == 200;
    } on DioException catch (e) {
      final serverMessage = _extractMessageFromResponse(e.response?.data);
      throw Exception(
        'Error al actualizar perfil: ${serverMessage ?? e.message}',
      );
    }
  }

  String? _extractMessageFromResponse(dynamic data) {
    try {
      if (data == null) return null;
      if (data is String) return data;
      if (data is Map) {
        if (data['message'] != null) return data['message'].toString();
        if (data['error'] != null) return data['error'].toString();
        if (data['errors'] != null) {
          final errors = data['errors'];
          if (errors is Map) {
            final msgs = <String>[];
            errors.forEach((k, v) {
              if (v is List)
                msgs.addAll(v.map((e) => e.toString()));
              else
                msgs.add(v.toString());
            });
            return msgs.join(' | ');
          }
          return errors.toString();
        }
        return null;
      }
      return data.toString();
    } catch (_) {
      return null;
    }
  }
}