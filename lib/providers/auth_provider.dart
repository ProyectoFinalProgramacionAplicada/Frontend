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
      final tokenDto = await _service
          .login(UserLoginDto(email: email, password: password))
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw Exception(
              'La conexión tardó demasiado. Intentá de nuevo.',
            ),
          );

      if (tokenDto.token == null) throw Exception("Token inválido");

      ApiClient().setToken(tokenDto.token!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', tokenDto.token!);

      try {
        user = await _service.getMe().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw Exception(
            'No se pudo obtener tu perfil. Intentá de nuevo.',
          ),
        );
      } catch (e) {
        // If fetching user fails (e.g. token invalid), clear saved token and state
        ApiClient().clearToken();
        await prefs.remove('auth_token');
        user = null;
        rethrow;
      }
    } catch (e) {
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
