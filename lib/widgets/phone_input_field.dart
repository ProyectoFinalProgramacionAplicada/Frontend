import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../core/constants/app_colors.dart';

class PhoneInputField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final void Function(String phoneNumber)? onChanged;
  final void Function(bool isValid)? onValidChanged;
  final String? errorText;
  final String initialCountryCode;

  const PhoneInputField({
    super.key,
    this.label = 'Teléfono',
    this.initialValue,
    this.onChanged,
    this.onValidChanged,
    this.errorText,
    this.initialCountryCode = 'BO', // Bolivia por defecto
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  final TextEditingController _controller = TextEditingController();

  // Estado del país seleccionado - se mantiene aunque el widget se reconstruya
  late PhoneNumber _phoneNumber;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Inicializar con el país por defecto
    _phoneNumber = PhoneNumber(isoCode: widget.initialCountryCode);
    _initializePhone();
  }

  Future<void> _initializePhone() async {
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      try {
        // Parsear el número inicial para extraer país y número
        final parsed = await PhoneNumber.getRegionInfoFromPhoneNumber(
          widget.initialValue!,
        );
        if (mounted) {
          setState(() {
            _phoneNumber = parsed;
            // Extraer solo el número sin el código de país
            final dialCode = parsed.dialCode ?? '';
            final fullNumber = parsed.phoneNumber ?? '';
            _controller.text = fullNumber
                .replaceFirst('+$dialCode', '')
                .replaceFirst(dialCode, '');
            _isInitialized = true;
          });
        }
      } catch (_) {
        // Si falla el parseo, usar el valor raw limpiando +591 si existe
        if (mounted) {
          _controller.text = widget.initialValue!
              .replaceFirst('+591', '')
              .replaceFirst('591', '');
          setState(() => _isInitialized = true);
        }
      }
    } else {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Construye el número completo en formato E.164
  /// Ejemplo: "+591" + "77310481" = "+59177310481"
  String _buildFullPhoneNumber() {
    final dialCode = _phoneNumber.dialCode ?? '+591';
    final number = _controller.text.replaceAll(
      RegExp(r'\D'),
      '',
    ); // Solo dígitos
    if (number.isEmpty) return '';
    return '$dialCode$number';
  }

  @override
  Widget build(BuildContext context) {
    // No renderizar hasta que esté inicializado para evitar flicker
    if (!_isInitialized) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neutralLight, width: 1.5),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ),
        // Phone Input
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? AppColors.errorColor
                  : AppColors.neutralLight,
              width: 1.5,
            ),
          ),
          child: InternationalPhoneNumberInput(
            onInputChanged: (PhoneNumber number) {
              // Guardar el país seleccionado en el estado interno
              // Esto evita que se resetee cuando el padre se reconstruye
              _phoneNumber = number;

              // Construir y notificar el número completo en formato E.164
              final fullPhone = _buildFullPhoneNumber();
              widget.onChanged?.call(fullPhone);
            },
            onInputValidated: (bool isValid) {
              widget.onValidChanged?.call(isValid);
            },
            selectorConfig: const SelectorConfig(
              selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
              useBottomSheetSafeArea: true,
              leadingPadding: 12,
              setSelectorButtonAsPrefixIcon: true,
              trailingSpace: false,
            ),
            ignoreBlank: false,
            autoValidateMode: AutovalidateMode.disabled,
            selectorTextStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary,
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary,
            ),
            // IMPORTANTE: Usar el estado interno _phoneNumber
            // que mantiene el país seleccionado por el usuario
            initialValue: _phoneNumber,
            textFieldController: _controller,
            formatInput: true,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: false,
            ),
            inputDecoration: InputDecoration(
              hintText: '77310481',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.neutralDark.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 14,
              ),
              isDense: true,
            ),
            searchBoxDecoration: InputDecoration(
              labelText: 'Buscar país',
              labelStyle: GoogleFonts.inter(fontSize: 14),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            locale: 'es',
            countries: const [
              'BO', // Bolivia (default)
              'AR', // Argentina
              'BR', // Brasil
              'CL', // Chile
              'CO', // Colombia
              'EC', // Ecuador
              'PY', // Paraguay
              'PE', // Perú
              'UY', // Uruguay
              'VE', // Venezuela
              'MX', // México
              'US', // Estados Unidos
              'ES', // España
            ],
          ),
        ),
        // Error text
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.errorColor,
              ),
            ),
          ),
      ],
    );
  }
}
