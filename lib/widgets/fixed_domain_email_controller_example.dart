// EJEMPLO DE USO DEL FixedDomainEmailController
// ================================================

import 'package:flutter/material.dart';
import 'fixed_domain_email_controller.dart';

/// Ejemplo completo de cómo usar el FixedDomainEmailController
/// en cualquier formulario de tu aplicación.
class EmailFieldExample extends StatefulWidget {
  const EmailFieldExample({super.key});

  @override
  State<EmailFieldExample> createState() => _EmailFieldExampleState();
}

class _EmailFieldExampleState extends State<EmailFieldExample> {
  // 1️⃣ CREAR EL CONTROLADOR
  // ========================
  // Usa FixedDomainEmailController en lugar de TextEditingController
  final FixedDomainEmailController _emailController =
      FixedDomainEmailController();

  // También puedes inicializar con un username predeterminado:
  // final FixedDomainEmailController _emailController =
  //     FixedDomainEmailController(initialUsername: 'victoria');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email con dominio fijo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 2️⃣ USAR EN UN TEXTFIELD
            // ========================
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'usuario@gmail.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 20),

            // 3️⃣ BOTÓN PARA OBTENER EL EMAIL COMPLETO
            // ========================================
            ElevatedButton(
              onPressed: () {
                // Obtener el email completo (username + @gmail.com)
                final fullEmail = _emailController.email;

                // O solo el username sin el dominio
                final username = _emailController.username;

                print('Email completo: $fullEmail');
                print('Username solo: $username');

                // Ejemplo: victoria@gmail.com
                // Email completo: victoria@gmail.com
                // Username solo: victoria
              },
              child: const Text('Obtener Email'),
            ),

            const SizedBox(height: 20),

            // 4️⃣ EJEMPLO CON TEXTFORMFIELD Y VALIDACIÓN
            // ==========================================
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email (con validación)',
                hintText: 'usuario@gmail.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                // El value contendrá el email completo
                if (value == null || value.isEmpty) {
                  return 'El email es requerido';
                }

                // Validar el username (parte antes del @)
                final username = _emailController.username;
                if (username.isEmpty) {
                  return 'Ingresa tu usuario';
                }

                // Puedes agregar más validaciones
                if (username.length < 3) {
                  return 'El usuario debe tener al menos 3 caracteres';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // 5️⃣ ESTABLECER USERNAME PROGRAMÁTICAMENTE
            // =========================================
            ElevatedButton(
              onPressed: () {
                // Puedes cambiar el username programáticamente
                _emailController.username = 'nuevousuario';

                // El email automáticamente será: nuevousuario@gmail.com
              },
              child: const Text('Establecer username'),
            ),

            const SizedBox(height: 40),

            // 📝 NOTAS IMPORTANTES
            // ====================
            const Text(
              'CARACTERÍSTICAS:\n'
              '✅ El usuario solo puede escribir antes del @\n'
              '✅ El dominio @gmail.com no se puede borrar\n'
              '✅ El cursor se reposiciona automáticamente\n'
              '✅ Compatible con TextField y TextFormField\n'
              '✅ Funciona con validación de formularios\n'
              '✅ Mantiene el estilo visual de tu UI',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// EJEMPLO 2: Uso en un formulario de Login
/// =========================================
class LoginFormExample extends StatefulWidget {
  const LoginFormExample({super.key});

  @override
  State<LoginFormExample> createState() => _LoginFormExampleState();
}

class _LoginFormExampleState extends State<LoginFormExample> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = FixedDomainEmailController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Obtener el email completo para enviar al backend
    final email = _emailController.email;
    final password = _passwordController.text;

    print('Logging in with:');
    print('Email: $email');
    print('Password: $password');

    // Aquí llamarías tu servicio de autenticación
    // await authService.login(email, password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Campo de Email con dominio fijo
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'usuario@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El email es requerido';
                  }
                  if (_emailController.username.isEmpty) {
                    return 'Ingresa tu usuario';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Campo de Contraseña (normal)
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es requerida';
                  }
                  if (value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Botón de Login
              ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
