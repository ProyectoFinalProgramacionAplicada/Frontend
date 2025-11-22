import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';
import '../../dto/auth/user_update_dto.dart';
import '../../core/utils/app_colors.dart'; // Ajusta según tu estructura

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _email = '';
  String? _avatarUrl; // URL del backend
  
  bool _isLoading = true;
  bool _isSaving = false;

  // URL base para imágenes (Ajusta según tu entorno: localhost o Azure)
  // Para emulador Android usa: http://10.0.2.2:5129
  final String _baseUrl = 'http://10.0.2.2:5129'; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getMe();
      setState(() {
        _nameController.text = user.displayName ?? '';
        _phoneController.text = user.phone ?? '';
        _email = user.email ?? '';
        _avatarUrl = user.avatarUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error cargando perfil: $e', isError: true);
    }
  }

  // Lógica para cambiar foto
  Future<void> _pickAndUploadImage() async {
    // 1. Seleccionar imagen
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return; // Usuario canceló

    setState(() => _isLoading = true);
    
    try {
      // 2. Leer los bytes de la imagen (Universal)
      final bytes = await image.readAsBytes();
      
      // 3. Enviar bytes y nombre al servicio
      final newUrl = await _authService.uploadAvatar(bytes, image.name);
      
      if (newUrl != null) {
        setState(() => _avatarUrl = newUrl);
        _showMessage('Foto actualizada correctamente');
      }
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Lógica para actualizar texto
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final dto = UserUpdateDto(
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      
      final success = await _authService.updateProfile(dto);
      if (success) {
        _showMessage('Perfil actualizado');
        // Opcional: recargar para asegurar datos
      }
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Diálogo para cambiar contraseña
  void _showChangePasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final formPassKey = GlobalKey<FormState>();
    bool isLoadingPass = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Cambiar Contraseña'),
              content: Form(
                key: formPassKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomInput(
                      controller: oldPassCtrl,
                      label: 'Contraseña actual',
                      hint: 'Ingresa tu clave actual',
                      isPassword: true,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 15),
                    CustomInput(
                      controller: newPassCtrl,
                      label: 'Nueva contraseña',
                      hint: 'Mínimo 6 caracteres',
                      isPassword: true,
                      validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isLoadingPass ? null : () async {
                    if (!formPassKey.currentState!.validate()) return;
                    
                    setStateDialog(() => isLoadingPass = true);
                    try {
                      await _authService.changePassword(
                        oldPassCtrl.text,
                        newPassCtrl.text,
                      );
                      Navigator.pop(context);
                      _showMessage('Contraseña cambiada con éxito');
                    } catch (e) {
                      // Mostramos error en el snackbar principal, no en el dialogo
                      Navigator.pop(context);
                      _showMessage(e.toString(), isError: true);
                    }
                  },
                  child: Text(isLoadingPass ? '...' : 'Cambiar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Construir la URL completa de la imagen si existe
    ImageProvider? imageProvider;
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        final fullUrl = _avatarUrl!.startsWith('http') 
            ? _avatarUrl! 
            : '$_baseUrl$_avatarUrl';
            
        // Imprimimos para depurar (mira tu consola de VS Code)
        print("Intentando cargar imagen desde: $fullUrl"); 
        
        imageProvider = NetworkImage(fullUrl);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- AVATAR ---
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: imageProvider,
                          child: _avatarUrl == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                              onPressed: _pickAndUploadImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- FORMULARIO ---
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Nombre
                        CustomInput(
                          controller: _nameController,
                          label: 'Nombre Visible',
                          hint: 'Ej. Juan Perez',
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        // Teléfono con validación
                        CustomInput(
                          controller: _phoneController,
                          label: 'Teléfono',
                          hint: '+591 70000000',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Requerido';
                            // Regex para código país (ej: +591...)
                            final regex = RegExp(r'^\+[0-9]{1,3}\s?[0-9]{6,14}$');
                            if (!regex.hasMatch(value)) {
                              return 'Incluye código país (ej. +591 74666380)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Botón Cambiar Contraseña
                        OutlinedButton.icon(
                          onPressed: _showChangePasswordDialog,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Cambiar Contraseña'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        
                        const SizedBox(height: 30),

                        // Botón Guardar
                        PrimaryButton(
                          label: 'Guardar Cambios',
                          onPressed: () => _saveProfile(),
                          isLoading: _isSaving,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}