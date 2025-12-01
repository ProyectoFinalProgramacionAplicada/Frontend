import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/phone_formatter.dart';
import '../core/constants/app_colors.dart';

/// Widget elegante estilo AppStore para mostrar un número de teléfono E.164.
///
/// Muestra la bandera del país, el nombre y el número formateado:
/// ```
/// 🇨🇱 Chile
/// +56 9 9876 5432
/// ```
///
/// Ejemplo de uso:
/// ```dart
/// PhoneDisplayWidget(phone: '+5699876543')
/// ```
class PhoneDisplayWidget extends StatelessWidget {
  final String? phone;
  final bool compact;
  final double flagSize;
  final Color? textColor;
  final Color? subtitleColor;

  const PhoneDisplayWidget({
    super.key,
    required this.phone,
    this.compact = false,
    this.flagSize = 24,
    this.textColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay teléfono, no mostrar nada
    if (phone == null || phone!.isEmpty) {
      return const SizedBox.shrink();
    }

    final result = PhoneFormatter.format(phone);
    final primaryColor = textColor ?? AppColors.secondary;
    final secondaryColor = subtitleColor ?? Colors.grey[600];

    if (compact) {
      // Versión compacta en una sola línea: 🇨🇱 +56 9 9876 5432
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(result.flag, style: TextStyle(fontSize: flagSize)),
          const SizedBox(width: 8),
          Text(
            result.formattedNumber,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: primaryColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    }

    // Versión expandida con nombre del país
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Bandera emoji
        Container(
          width: flagSize + 12,
          height: flagSize + 12,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(result.flag, style: TextStyle(fontSize: flagSize)),
        ),
        const SizedBox(width: 12),
        // Columna con país y número
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.countryName,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              result.formattedNumber,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget minimalista que solo muestra el número formateado con la bandera.
/// Ideal para usar en lugares donde se necesita ahorrar espacio.
class PhoneDisplayInline extends StatelessWidget {
  final String? phone;
  final TextStyle? style;

  const PhoneDisplayInline({super.key, required this.phone, this.style});

  @override
  Widget build(BuildContext context) {
    if (phone == null || phone!.isEmpty) {
      return const SizedBox.shrink();
    }

    final result = PhoneFormatter.format(phone);
    final textStyle = style ?? TextStyle(fontSize: 14, color: Colors.grey[600]);

    return Text('${result.flag} ${result.formattedNumber}', style: textStyle);
  }
}
