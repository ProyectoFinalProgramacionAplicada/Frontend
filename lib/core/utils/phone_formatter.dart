/// Utilidades para formatear números de teléfono E.164 de forma visual.
///
/// Ejemplo de uso:
/// ```dart
/// final formatted = PhoneFormatter.format('+5699876543');
/// // Retorna: PhoneFormatResult(
/// //   flag: '🇨🇱',
/// //   countryName: 'Chile',
/// //   formattedNumber: '+56 9 9876 5432',
/// //   dialCode: '+56',
/// // )
/// ```

class PhoneFormatResult {
  final String flag;
  final String countryName;
  final String formattedNumber;
  final String dialCode;

  const PhoneFormatResult({
    required this.flag,
    required this.countryName,
    required this.formattedNumber,
    required this.dialCode,
  });
}

class PhoneFormatter {
  // Mapeo de código de país a información del país
  static const Map<String, _CountryInfo> _countries = {
    '591': _CountryInfo('🇧🇴', 'Bolivia', '+591'),
    '54': _CountryInfo('🇦🇷', 'Argentina', '+54'),
    '55': _CountryInfo('🇧🇷', 'Brasil', '+55'),
    '56': _CountryInfo('🇨🇱', 'Chile', '+56'),
    '57': _CountryInfo('🇨🇴', 'Colombia', '+57'),
    '593': _CountryInfo('🇪🇨', 'Ecuador', '+593'),
    '595': _CountryInfo('🇵🇾', 'Paraguay', '+595'),
    '51': _CountryInfo('🇵🇪', 'Perú', '+51'),
    '598': _CountryInfo('🇺🇾', 'Uruguay', '+598'),
    '58': _CountryInfo('🇻🇪', 'Venezuela', '+58'),
    '52': _CountryInfo('🇲🇽', 'México', '+52'),
    '1': _CountryInfo('🇺🇸', 'Estados Unidos', '+1'),
    '34': _CountryInfo('🇪🇸', 'España', '+34'),
  };

  /// Formatea un número E.164 a un formato visual amigable.
  ///
  /// [phone] debe ser un string como "+59177310481" o "59177310481"
  ///
  /// Retorna un [PhoneFormatResult] con bandera, nombre del país y número formateado.
  static PhoneFormatResult format(String? phone) {
    if (phone == null || phone.isEmpty) {
      return const PhoneFormatResult(
        flag: '📱',
        countryName: 'Desconocido',
        formattedNumber: 'Sin teléfono',
        dialCode: '',
      );
    }

    // Limpiar el número (quitar espacios y el + inicial si existe)
    String cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone.startsWith('+')) {
      cleanPhone = cleanPhone.substring(1);
    }

    // Buscar el país por código
    String? matchedCode;
    _CountryInfo? countryInfo;

    // Intentar códigos de 3, 2 y 1 dígito (en ese orden para mayor especificidad)
    for (int len = 3; len >= 1; len--) {
      if (cleanPhone.length >= len) {
        final code = cleanPhone.substring(0, len);
        if (_countries.containsKey(code)) {
          matchedCode = code;
          countryInfo = _countries[code];
          break;
        }
      }
    }

    // Si no encontramos el país, devolver el número limpio
    if (matchedCode == null || countryInfo == null) {
      return PhoneFormatResult(
        flag: '🌍',
        countryName: 'Internacional',
        formattedNumber: '+$cleanPhone',
        dialCode: '',
      );
    }

    // Extraer el número nacional (sin código de país)
    final nationalNumber = cleanPhone.substring(matchedCode.length);

    // Formatear según el país
    final formattedNational = _formatNationalNumber(
      matchedCode,
      nationalNumber,
    );

    return PhoneFormatResult(
      flag: countryInfo.flag,
      countryName: countryInfo.name,
      formattedNumber: '${countryInfo.dialCode} $formattedNational',
      dialCode: countryInfo.dialCode,
    );
  }

  /// Formatea el número nacional según las reglas del país.
  static String _formatNationalNumber(String countryCode, String number) {
    switch (countryCode) {
      case '56': // Chile: 9 XXXX XXXX
        if (number.length == 9 && number.startsWith('9')) {
          return '${number.substring(0, 1)} ${number.substring(1, 5)} ${number.substring(5)}';
        }
        break;

      case '591': // Bolivia: 7XXXXXXX o 6XXXXXXX (8 dígitos)
        if (number.length == 8) {
          return '${number.substring(0, 1)} ${number.substring(1, 4)} ${number.substring(4)}';
        }
        break;

      case '54': // Argentina: 9 11 XXXX XXXX (móvil) o 11 XXXX XXXX (fijo)
        if (number.length >= 10) {
          if (number.startsWith('9')) {
            // Móvil con prefijo 9
            return '9 ${number.substring(1, 3)} ${number.substring(3, 7)} ${number.substring(7)}';
          } else {
            // Sin prefijo 9
            return '${number.substring(0, 2)} ${number.substring(2, 6)} ${number.substring(6)}';
          }
        }
        break;

      case '51': // Perú: 9 XXXX XXXX
        if (number.length == 9 && number.startsWith('9')) {
          return '${number.substring(0, 1)} ${number.substring(1, 5)} ${number.substring(5)}';
        }
        break;

      case '52': // México: 55 XXXX XXXX (CDMX) o código de área + número
        if (number.length == 10) {
          return '${number.substring(0, 2)} ${number.substring(2, 6)} ${number.substring(6)}';
        }
        break;

      case '57': // Colombia: 3XX XXX XXXX
        if (number.length == 10 && number.startsWith('3')) {
          return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
        }
        break;

      case '593': // Ecuador: 9X XXX XXXX
        if (number.length == 9) {
          return '${number.substring(0, 2)} ${number.substring(2, 5)} ${number.substring(5)}';
        }
        break;

      case '595': // Paraguay: 9XX XXX XXX
        if (number.length == 9) {
          return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
        }
        break;

      case '598': // Uruguay: 9X XXX XXX
        if (number.length == 8) {
          return '${number.substring(0, 2)} ${number.substring(2, 5)} ${number.substring(5)}';
        }
        break;

      case '58': // Venezuela: 4XX XXX XXXX
        if (number.length == 10) {
          return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
        }
        break;

      case '55': // Brasil: XX XXXXX XXXX
        if (number.length == 11) {
          return '${number.substring(0, 2)} ${number.substring(2, 7)} ${number.substring(7)}';
        }
        break;

      case '1': // USA/Canada: XXX XXX XXXX
        if (number.length == 10) {
          return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
        }
        break;

      case '34': // España: XXX XX XX XX
        if (number.length == 9) {
          return '${number.substring(0, 3)} ${number.substring(3, 5)} ${number.substring(5, 7)} ${number.substring(7)}';
        }
        break;
    }

    // Formato genérico si no coincide con ninguna regla específica
    if (number.length > 6) {
      return '${number.substring(0, 3)} ${number.substring(3)}';
    }
    return number;
  }

  /// Obtiene solo la bandera emoji para un número E.164.
  static String getFlag(String? phone) {
    return format(phone).flag;
  }

  /// Obtiene solo el nombre del país para un número E.164.
  static String getCountryName(String? phone) {
    return format(phone).countryName;
  }
}

class _CountryInfo {
  final String flag;
  final String name;
  final String dialCode;

  const _CountryInfo(this.flag, this.name, this.dialCode);
}
