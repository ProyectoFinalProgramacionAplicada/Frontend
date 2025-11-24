import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../dto/auth/app_role.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';

/// Pantalla de login completamente rediseñada para TruekApp
/// Incluye: animaciones, validación, responsividad, y UI moderna minimalista
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Controladores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Estados
  bool _isLoading = false;
  String _errorMessage = '';

  // Controladores de animación
  late AnimationController _fadeInController;

  late AnimationController _slideInputsController;
  late AnimationController _logoController;
  late AnimationController _lottieController;

  late Animation<double> _fadeInAnimation;

  late Animation<Offset> _slideInputsAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Animación Fade-in para la pantalla completa (más lenta)
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeInController, curve: Curves.easeInOut),
    );

    // (El logo utiliza _logoController para su entrada animada)

    // Controlador específico para la entrada del logo (intro tipo "Marvel")
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Animación Slide para inputs (más lenta)
    _slideInputsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideInputsAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideInputsController,
            curve: Curves.easeInOut,
          ),
        );

    // Controlador para Lottie
    _lottieController = AnimationController(vsync: this);
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        // Lanzamos la intro del logo primero
        _logoController.forward();
        // (no se usa un scaleLogoController adicional — _logoController maneja la entrada)
        _fadeInController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _slideInputsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _slideInputsController.dispose();
    _lottieController.dispose();
    _logoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida el email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  /// Valida la contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  /// Maneja el login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Inicia animación de Lottie (usar period explícito para evitar excepción en web)
    _lottieController.repeat(period: const Duration(milliseconds: 1200));

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(email, password);

      // Haptic feedback
      HapticFeedback.lightImpact();

      if (!mounted) return;

      final role = authProvider.currentUser?.role;
      if (role == AppRole.Admin) {
        Navigator.pushReplacementNamed(context, AppRoutes.adminActiveUsers);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted) {
        _showErrorSnackBar(_errorMessage);
      }
    } finally {
      if (mounted) {
        _lottieController.stop();
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Muestra snackbar de error con animación
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(4.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Construye el logo animado con flechas de trueque
  Widget _buildAnimatedLogo() {
    // Solo el icono (sin fondo). Tamaño protagonista.
    const double iconSize = 100.0; // puedes ajustar entre 80-120

    return FadeTransition(
      opacity: _logoOpacityAnimation,
      child: SlideTransition(
        position: _logoSlideAnimation,
        child: ScaleTransition(
          scale: _logoScaleAnimation,
          child: Center(
            child: Icon(
              Icons.swap_horiz_outlined,
              size: iconSize,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el formulario con inputs
  Widget _buildForm() {
    return SlideTransition(
      position: _slideInputsAnimation,
      child: FadeTransition(
        opacity: _fadeInAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email Input
              CustomInput(
                label: 'Email',
                hint: 'tu@email.com',
                controller: _emailController,
                isEmail: true,
                validator: _validateEmail,
                prefixIcon: Icons.mail_outline,
              ),
              SizedBox(height: 4.h),

              // Password Input
              CustomInput(
                label: 'Contraseña',
                hint: '••••••••',
                controller: _passwordController,
                isPassword: true,
                validator: _validatePassword,
                prefixIcon: Icons.lock_outline,
              ),
              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    'Olvidé mi contraseña',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final _emailCtrl = TextEditingController(
      text: _emailController.text.trim(),
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: TextField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final email = _emailCtrl.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Introduce tu email')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              try {
                final msg = await AuthService().forgotPassword(email);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
              } catch (e) {
                final msg = e.toString().replaceAll('Exception: ', '');
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  /// Construye el botón de login
  Widget _buildLoginButton() {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Loader Lottie
                  SizedBox(
                    width: 50.w,
                    height: 50.w,
                    child: Lottie.asset(
                      'assets/lotties/loader.json',
                      controller: _lottieController,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Iniciando sesión...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutralDark,
                    ),
                  ),
                ],
              ),
            )
          : PrimaryButton(
              label: 'Iniciar Sesión',
              onPressed: _handleLogin,
              isLoading: _isLoading,
              isEnabled: !_isLoading,
              height: 50,
            ),
    );
  }

  /// Construye el footer con link a crear cuenta
  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Padding(
        padding: EdgeInsets.only(top: 3.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿Nuevo por aquí? ',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.neutralDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.register);
              },
              child: Text(
                'Crear cuenta',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 600),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Espaciador superior
                              SizedBox(height: 1.h),

                              // Logo animado
                              _buildAnimatedLogo(),
                              SizedBox(height: 3.h),

                              // Frase principal (título grande)
                              FadeTransition(
                                opacity: _fadeInAnimation,
                                child: Text(
                                  'Volvé a darle valor\n a tus cosas.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondary,
                                    height: 1.18,
                                  ),
                                ),
                              ),
                              SizedBox(height: 1.h),

                              // Texto secundario (más pequeño y gris)
                              FadeTransition(
                                opacity: _fadeInAnimation,
                                child: Text(
                                  'Iniciá sesión para volver a conectar con tu comunidad.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.neutralDark,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4.h),

                              // Formulario
                              _buildForm(),
                              SizedBox(height: 3.h),

                              // Botón de login
                              _buildLoginButton(),

                              // Footer
                              _buildFooter(),

                              // Espaciador inferior
                              SizedBox(height: 1.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
