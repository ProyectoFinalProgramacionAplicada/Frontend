import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../core/constants/app_colors.dart';

/// Widget de input de teléfono con selector de país para TruekApp.
/// Usa intl_phone_number_input internamente.
/// Mantiene la estética consistente con los demás inputs de la app.
class PhoneInputField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final void Function(String phoneNumber)? onChanged;
  final void Function(bool isValid)? onValidChanged;
  final String? errorText;

  const PhoneInputField({
    super.key,
    this.label = 'Teléfono',
    this.initialValue,
    this.onChanged,
    this.onValidChanged,
    this.errorText,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  final TextEditingController _controller = TextEditingController();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'BO'); // Bolivia default
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _initializePhone();
  }

  Future<void> _initializePhone() async {
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      try {
        final parsed = await PhoneNumber.getRegionInfoFromPhoneNumber(
          widget.initialValue!,
        );
        if (mounted) {
          setState(() {
            _phoneNumber = parsed;
            _controller.text =
                parsed.phoneNumber?.replaceFirst('+${parsed.dialCode}', '') ??
                '';
          });
        }
      } catch (_) {
        // If parsing fails, just use the raw value
        _controller.text = widget.initialValue!.replaceFirst('+591', '');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              setState(() => _phoneNumber = number);
              // Return the complete phone string to parent
              widget.onChanged?.call(number.phoneNumber ?? '');
            },
            onInputValidated: (bool isValid) {
              setState(() => _isValid = isValid);
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
