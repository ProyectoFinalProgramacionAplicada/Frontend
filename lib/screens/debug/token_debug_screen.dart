import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import 'package:flutter/services.dart';

class TokenDebugScreen extends StatefulWidget {
  const TokenDebugScreen({super.key});

  @override
  State<TokenDebugScreen> createState() => _TokenDebugScreenState();
}

class _TokenDebugScreenState extends State<TokenDebugScreen> {
  String? _token;
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('auth_token');
    _controller.text = t ?? '';
    setState(() {
      _token = t;
      _loading = false;
    });
  }

  Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    final newToken = _controller.text.trim();
    if (newToken.isEmpty) return;
    await prefs.setString('auth_token', newToken);
    ApiClient().setToken(newToken);
    setState(() => _token = newToken);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    ApiClient().clearToken();
    _controller.clear();
    setState(() => _token = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug: Token')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Auth token almacenado (auth_token):'),
                  const SizedBox(height: 8),
                  SelectableText(_token ?? '<no token>'),
                  const SizedBox(height: 16),
                  const Text('Editar / pegar token para pruebas'),
                  const SizedBox(height: 8),
                  TextField(controller: _controller, maxLines: 2),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await _saveToken();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token guardado y aplicado'),
                            ),
                          );
                        },
                        child: const Text('Guardar y aplicar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _token ?? ''),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token copiado al clipboard'),
                            ),
                          );
                        },
                        child: const Text('Copiar token'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _clearToken,
                        child: const Text('Borrar token'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Instrucciones:'),
                  const SizedBox(height: 8),
                  const Text(
                    '- Usa "Guardar y aplicar" para probar llamadas protegidas desde la app.',
                  ),
                  const Text(
                    '- Copia el token y úsalo en PowerShell con Authorization: Bearer <token>.',
                  ),
                ],
              ),
      ),
    );
  }
}
