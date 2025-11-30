// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dto/auth/user_info_dto.dart';
import '../dto/auth/user_login_dto.dart';
import '../dto/auth/user_register_dto.dart';
import '../dto/auth/user_update_dto.dart'; // <--- IMPORTANTE
import '../services/auth_service.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  UserInfoDto? user;
  bool isLoading = false;
  bool get isLoggedIn => user != null;

  // Getter para facilitar acceso
  UserInfoDto? get currentUser => user;

  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      // El backend ahora devuelve { token, user } en LoginResponseDto
      final loginResponse = await _service
          .login(UserLoginDto(email: email, password: password))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'La conexión tardó demasiado. Intentá de nuevo.',
            ),
          );

      if (loginResponse.token == null) throw Exception("Token inválido");

      // Guardar el token
      ApiClient().setToken(loginResponse.token!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', loginResponse.token!);

      // ✅ IMPORTANTE: Usar el usuario que viene en la respuesta del login
      // Ya no necesitamos llamar a getMe() porque el backend envía el user
      if (loginResponse.user != null) {
        user = loginResponse.user;
        print('=== Usuario cargado del login ===');
        print('displayName: ${user?.displayName}');
        print('email: ${user?.email}');
        print('phone: ${user?.phone}');
      } else {
        // Fallback: si por alguna razón no viene el user, llamar a getMe()
        user = await _service.getMe().timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception(
            'No se pudo obtener tu perfil. Intentá de nuevo.',
          ),
        );
      }
    } catch (e) {
      // Si falla, limpiar estado
      ApiClient().clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      user = null;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      ApiClient().setToken(token);
      user = await _service.getMe();
      notifyListeners();
      return true;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      return false;
    }
  }

  Future<void> register(UserRegisterDto dto) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.register(dto);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- NUEVOS MÉTODOS DE EDICIÓN ---

  // 1. Actualizar Datos (Nombre/Teléfono)
  Future<void> updateProfile(UserUpdateDto dto) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.updateProfile(dto);
      // Refrescamos los datos del usuario localmente
      user = await _service.getMe();
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 2. Actualizar Avatar
  Future<void> updateAvatar(List<int> bytes, String fileName) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.uploadAvatar(bytes, fileName);
      user = await _service.getMe(); // Refrescar para ver la foto nueva
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 3. Cambiar Contraseña
  Future<void> changePassword(String oldPassword, String newPassword) async {
    // No necesitamos refrescar el usuario, solo llamar al servicio
    await _service.changePassword(oldPassword, newPassword);
  }

  // ----------------------------------

  void logout() {
    ApiClient().clearToken();
    user = null;
    SharedPreferences.getInstance().then((prefs) => prefs.remove('auth_token'));
    notifyListeners();
  }
}
