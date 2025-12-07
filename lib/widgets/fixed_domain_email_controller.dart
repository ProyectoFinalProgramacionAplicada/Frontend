import 'package:flutter/material.dart';

/// TextEditingController personalizado que mantiene un dominio fijo (@gmail.com)
/// y solo permite al usuario editar la parte del nombre de usuario.
///
/// Funcionalidades:
/// - Muestra "@gmail.com" desde el inicio
/// - El usuario solo puede escribir ANTES del @
/// - El dominio no se puede borrar ni modificar
/// - El cursor se reposiciona automáticamente antes del @
///
/// Uso:
/// ```dart
/// final controller = FixedDomainEmailController();
/// TextField(controller: controller)
/// ```
class FixedDomainEmailController extends TextEditingController {
  static const String domain = '@gmail.com';

  FixedDomainEmailController({String? initialUsername})
    : super(text: (initialUsername ?? '') + domain) {
    addListener(_handleTextChange);
  }

  /// Obtiene solo la parte del username (sin el dominio)
  String get username {
    final fullText = text;
    if (fullText.contains('@')) {
      return fullText.substring(0, fullText.indexOf('@'));
    }
    return fullText;
  }

  /// Obtiene el email completo (username + dominio)
  String get email => username + domain;

  /// Establece solo el username, manteniendo el dominio
  set username(String newUsername) {
    final cleanUsername = newUsername.replaceAll('@', '').trim();
    text = cleanUsername + domain;
    // Posicionar cursor después del username
    selection = TextSelection.collapsed(offset: cleanUsername.length);
  }

  void _handleTextChange() {
    final currentText = text;

    // Si el texto no contiene el dominio o fue modificado, restaurarlo
    if (!currentText.endsWith(domain)) {
      // Extraer solo el username (antes del primer @, si existe)
      String extractedUsername = currentText;

      if (currentText.contains('@')) {
        extractedUsername = currentText.substring(0, currentText.indexOf('@'));
      } else {
        // Si no hay @, tomar todo menos los últimos caracteres del dominio que pudieron quedar
        extractedUsername = currentText.replaceAll(domain, '');
      }

      // Limpiar cualquier @ restante del username
      extractedUsername = extractedUsername.replaceAll('@', '');

      // Reconstruir el texto completo
      final newText = extractedUsername + domain;

      // Solo actualizar si realmente cambió algo
      if (newText != currentText) {
        // Guardar posición del cursor relativa al username
        final cursorPos = selection.baseOffset;
        final usernameLength = extractedUsername.length;

        // Actualizar texto
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            // Asegurar que el cursor esté dentro del username
            offset: cursorPos <= usernameLength ? cursorPos : usernameLength,
          ),
        );
      }
    } else {
      // El dominio está intacto, verificar posición del cursor
      final usernameLength = currentText.length - domain.length;

      // Si el cursor está después del username, moverlo al final del username
      if (selection.baseOffset > usernameLength) {
        value = TextEditingValue(
          text: currentText,
          selection: TextSelection.collapsed(offset: usernameLength),
        );
      }
    }
  }

  @override
  void dispose() {
    removeListener(_handleTextChange);
    super.dispose();
  }
}
