import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../dto/auth/user_register_dto.dart';
import '../../dto/auth/app_role.dart';
import '../../widgets/phone_input_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final Map<String, String?> _fieldErrors = {};
  bool _isLoading = false;

  // Password visibility toggles
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Phone state
  String _phoneNumber = '';

  // Animation controller for card entrance
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _cardAnimationController,
            curve: Curves.easeOut,
          ),
        );
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.register(
        UserRegisterDto(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneNumber.isEmpty ? null : _phoneNumber,
          role: AppRole.User,
        ),
      );

      // After register, go back to login
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // clear previous field errors
      _fieldErrors.clear();
      if (e is ValidationException) {
        e.errors.forEach((k, v) {
          _fieldErrors[k] = v.isNotEmpty ? v.first : null;
        });
        setState(() {});
        final msg = e.message ?? e.toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } else {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));

        // If the server reports the email is already registered, offer to go to login
        final lower = msg.toLowerCase();
        if (lower.contains('ya est') ||
            lower.contains('registrad') ||
            lower.contains('already')) {
          if (mounted) {
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Cuenta existente'),
                content: Text(
                  '$msg\n\n¿Deseas ir a Iniciar sesión en su lugar?',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Usar otro email'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                    child: const Text('Ir a Iniciar sesión'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Card(
                      color: AppColors.surface,
                      elevation: 6,
                      shadowColor: AppColors.shadowColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 4.h,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title
                              Text(
                                'Crear cuenta',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Completá tus datos para registrarte',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.neutralDark,
                                ),
                              ),
                              SizedBox(height: 3.h),

                              // Nombre Completo
                              _buildInputField(
                                controller: _nameController,
                                label: 'Nombre Completo',
                                hint: 'Tu nombre',
                                prefixIcon: Icons.person_outline,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'El nombre es requerido';
                                  }
                                  return null;
                                },
                                fieldError: _fieldErrors['name'],
                              ),
                              SizedBox(height: 2.h),

                              // Email
                              _buildInputField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'tu@email.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'El email es requerido';
                                  }
                                  final re = RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  );
                                  if (!re.hasMatch(v)) {
                                    return 'Email inválido';
                                  }
                                  return null;
                                },
                                fieldError: _fieldErrors['email'],
                              ),
                              SizedBox(height: 2.h),

                              // Phone with country selector
                              PhoneInputField(
                                label: 'Teléfono',
                                onChanged: (phone) {
                                  _phoneNumber = phone;
                                },
                                errorText: _fieldErrors['phone'],
                              ),
                              SizedBox(height: 2.h),

                              // Password
                              _buildInputField(
                                controller: _passwordController,
                                label: 'Contraseña',
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                obscureText: _obscurePassword,
                                onToggleObscure: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                validator: (v) => (v == null || v.length < 6)
                                    ? 'Mínimo 6 caracteres'
                                    : null,
                                fieldError: _fieldErrors['password'],
                              ),
                              SizedBox(height: 2.h),

                              // Confirm Password
                              _buildInputField(
                                controller: _confirmPasswordController,
                                label: 'Confirmar Contraseña',
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                obscureText: _obscureConfirmPassword,
                                onToggleObscure: () {
                                  setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  );
                                },
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Confirma tu contraseña';
                                  }
                                  if (v != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 3.h),

                              // Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _isLoading
                                      ? Center(
                                          key: const ValueKey('loading'),
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        )
                                      : ElevatedButton(
                                          key: const ValueKey('button'),
                                          onPressed: _handleRegister,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                          ),
                                          child: Text(
                                            'Crear cuenta',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                ),
                              ),

                              SizedBox(height: 2.h),

                              // Login link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '¿Ya tenés cuenta? ',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.neutralDark,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushReplacementNamed(
                                      context,
                                      AppRoutes.login,
                                    ),
                                    child: Text(
                                      'Iniciar sesión',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper widget to build styled input fields matching login screen
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
    String? fieldError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: isPassword ? obscureText : false,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.neutralDark.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.neutralDark,
              size: 20,
            ),
            suffixIcon: isPassword
                ? GestureDetector(
                    onTap: onToggleObscure,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        key: ValueKey<bool>(obscureText),
                        color: AppColors.neutralDark,
                        size: 20,
                      ),
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.neutralLight, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.neutralLight, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.errorColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.errorColor, width: 2),
            ),
            errorStyle: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.errorColor,
            ),
          ),
        ),
        if (fieldError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              fieldError,
              style: TextStyle(color: AppColors.errorColor, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
