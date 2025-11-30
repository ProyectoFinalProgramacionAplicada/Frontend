import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../dto/auth/user_login_dto.dart';
import '../dto/auth/user_register_dto.dart';
import '../dto/auth/login_response_dto.dart';
import '../dto/auth/user_info_dto.dart';
import '../dto/auth/user_update_dto.dart';
import '../dto/auth/forgot_password_dto.dart';
import '../dto/auth/reset_password_dto.dart';

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

  /// Login - Ahora devuelve LoginResponseDto con token + user
  Future<LoginResponseDto> login(UserLoginDto dto) async {
    try {
      final response = await _dio.post('/Auth/login', data: dto.toJson());
      var data = response.data;

      // DEBUG
      print('=== DEBUG login() ===');
      print('Raw login response: $data');

      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          // Si es solo el token como string (formato antiguo)
          return LoginResponseDto(token: data, user: null);
        }
      }

      if (data is Map<String, dynamic>) {
        final loginResponse = LoginResponseDto.fromJson(data);
        print('Token: ${loginResponse.token != null ? "OK" : "NULL"}');
        print('User displayName: ${loginResponse.user?.displayName}');
        return loginResponse;
      }

      throw Exception('Formato de respuesta inesperado del servidor');
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
      // DEBUG: Imprimir datos que se envían al backend
      print('=== DEBUG register() ===');
      print('Sending to backend: ${dto.toJson()}');

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

  /// Solicitar restablecimiento de contraseña
  /// El backend devuelve directamente el token de reset (sin envío de email)
  Future<String> forgotPassword(String email) async {
    try {
      final dto = ForgotPasswordDto(email: email);
      final resp = await _dio.post('/Auth/forgot-password', data: dto.toJson());

      // El backend devuelve el token directamente en la respuesta
      final data = resp.data;

      // Intentar extraer el token de la respuesta
      String? token;
      if (data is String && data.isNotEmpty) {
        token = data;
      } else if (data is Map) {
        token =
            data['token']?.toString() ??
            data['resetToken']?.toString() ??
            data['message']?.toString();
      }

      if (token == null || token.isEmpty) {
        throw Exception('No se recibió el token de recuperación.');
      }

      return token;
    } on DioException catch (e) {
      final resp = e.response;
      if (resp != null) {
        if (resp.statusCode == 404) {
          throw Exception('Usuario no encontrado.');
        }
        if (resp.statusCode == 400) {
          final serverMessage = _extractMessageFromResponse(resp.data);
          throw Exception(serverMessage ?? 'Email inválido.');
        }
        final serverMessage = _extractMessageFromResponse(resp.data);
        throw Exception(serverMessage ?? 'Error al procesar solicitud.');
      }
      throw Exception('Error de conexión. Verifica tu internet.');
    }
  }

  /// Verificar si un token de reset es válido
  Future<bool> verifyResetToken(String token) async {
    try {
      final resp = await _dio.get(
        '/Auth/verify-reset-token',
        queryParameters: {'token': token},
      );
      return resp.statusCode == 200;
    } on DioException catch (e) {
      final resp = e.response;
      if (resp != null && resp.statusCode == 400) {
        return false; // Token inválido o expirado
      }
      throw Exception('Error al verificar el token.');
    }
  }

  /// Restablecer contraseña con token
  Future<String> resetPassword(String token, String newPassword) async {
    try {
      final dto = ResetPasswordDto(token: token, newPassword: newPassword);
      final resp = await _dio.post('/Auth/reset-password', data: dto.toJson());

      final msg =
          _extractMessageFromResponse(resp.data) ??
          '¡Contraseña restablecida con éxito!';
      return msg;
    } on DioException catch (e) {
      final resp = e.response;
      if (resp != null) {
        final serverMessage = _extractMessageFromResponse(resp.data);
        if (resp.statusCode == 400) {
          throw Exception(serverMessage ?? 'Token inválido o expirado.');
        }
        throw Exception(serverMessage ?? 'Error al restablecer contraseña.');
      }
      throw Exception('Error de conexión. Verifica tu internet.');
    }
  }

  Future<UserInfoDto> getMe() async {
    final response = await _dio.get('/Auth/me');
    var data = response.data;

    // DEBUG: Imprimir respuesta cruda del backend
    print('=== DEBUG getMe() ===');
    print('Raw response data: $data');
    print('Response type: ${data.runtimeType}');

    if (data is String) {
      try {
        final parsed = jsonDecode(data);
        print('Parsed from string: $parsed');
        if (parsed is Map<String, dynamic>) return UserInfoDto.fromJson(parsed);
      } catch (_) {
        throw Exception('Unexpected response format from /Auth/me');
      }
    }
    if (data is Map<String, dynamic>) {
      print('displayName from backend: ${data['displayName']}');
      return UserInfoDto.fromJson(data);
    }
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
              if (v is List) {
                msgs.addAll(v.map((e) => e.toString()));
              } else {
                msgs.add(v.toString());
              }
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

  // 1. Cambiar Contraseña
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _dio.put(
        '/Users/me/password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      final msg = _extractMessageFromResponse(e.response?.data);
      throw Exception(msg ?? 'Error al cambiar contraseña');
    }
  }

  // 2. Subir Avatar
  Future<String?> uploadAvatar(List<int> bytes, String fileName) async {
    try {
      // Usamos fromBytes en lugar de fromFile. ¡Esto funciona en Móvil y Web!
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post('/Users/me/avatar', data: formData);

      if (response.statusCode == 200) {
        // El backend devuelve: { "avatarUrl": "/uploads/..." }
        return response.data['avatarUrl'];
      }
      return null;
    } on DioException catch (e) {
      print("Error subiendo avatar: $e");
      throw Exception('Error al subir imagen: ${e.message}');
    }
  }
}
