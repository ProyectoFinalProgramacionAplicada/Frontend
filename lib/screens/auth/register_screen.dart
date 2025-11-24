import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../dto/auth/user_register_dto.dart';
import '../../dto/auth/app_role.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final Map<String, String?> _fieldErrors = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // For now we call register but backend may require extra fields; this is a simple flow
      await auth.register(
        UserRegisterDto(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
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
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Crear cuenta',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'El email es requerido';
                          final re = RegExp(r'^[A-Za-z0-9._%+-]+@gmail\.com$');
                          if (!re.hasMatch(v))
                            return 'Email debe ser @gmail.com';
                          return null;
                        },
                      ),
                      if (_fieldErrors['email'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _fieldErrors['email']!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (ej: +59177310481)',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return null; // phone optional per schema
                          final re = RegExp(r'^\+[1-9]\d{6,14}$');
                          if (!re.hasMatch(v))
                            return 'Teléfono inválido. Formato +591...';
                          return null;
                        },
                      ),
                      if (_fieldErrors['phone'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _fieldErrors['phone']!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Mínimo 6 caracteres'
                            : null,
                      ),
                      if (_fieldErrors['password'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _fieldErrors['password']!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _handleRegister,
                              child: const Text('Crear cuenta'),
                            ),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿Ya tenés cuenta? '),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            ),
                            child: Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
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
    );
  }
}
