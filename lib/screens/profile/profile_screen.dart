import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Asumo que usas Provider por tu estructura
import '../../core/utils/app_colors.dart'; // Asegúrate de que esta ruta sea correcta
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';
import '../../dto/auth/user_update_dto.dart';
import '../../dto/auth/user_info_dto.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos editables
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Variable para el email (solo lectura) y Avatar
  String _email = '';
  String? _avatarUrl;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1. Cargar datos iniciales del Backend
  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getMe();
      setState(() {
        // Rellenamos los campos con la info que viene de la API
        _nameController.text = user.displayName ?? '';
        _phoneController.text = user.phone ?? '';
        _email = user.email ?? 'No disponible';
        _avatarUrl = user.avatarUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar perfil: $e')),
      );
    }
  }

  // 2. Guardar cambios
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updateDto = UserUpdateDto(
      displayName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    try {
      final success = await _authService.updateProfile(updateDto);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Perfil actualizado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        // Opcional: Recargar datos para asegurar frescura
        await _loadUserData(); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- SECCIÓN DE AVATAR ---
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _avatarUrl != null 
                              ? NetworkImage("https://truekapp.azurewebsites.net$_avatarUrl") // Ajusta la URL base si es necesario
                              : null,
                          child: _avatarUrl == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              onPressed: () {
                                // TODO: Implementar subida de imagen aquí
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Funcionalidad de foto pendiente de implementar en UI')),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- FORMULARIO DE DATOS ---
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email (Solo Lectura - Estética grisácea para indicar inhabilitado)
                        _buildReadOnlyField("Correo Electrónico", _email),
                        const SizedBox(height: 20),

                        // Nombre Visible (Editable)
                        // Nota: Uso CustomInput asumiendo sus parámetros. Ajusta si tu widget es diferente.
                        CustomInput(
                          controller: _nameController,
                          hint: 'Tu nombre visible',
                          label: 'Nombre de Usuario', // Si tu CustomInput tiene label
                          keyboardType: TextInputType.name,
                          // Validación simple
                          validator: (value) {
                             if (value == null || value.isEmpty) return 'El nombre es obligatorio';
                             return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Teléfono (Editable)
                        CustomInput(
                          controller: _phoneController,
                          hint: 'Tu número de celular',
                          label: 'Teléfono',
                          keyboardType: TextInputType.phone,
                        ),
                        
                        const SizedBox(height: 40),

                        // --- BOTÓN DE GUARDAR ---
                        SizedBox(
                          width: double.infinity,
                          height: 50, // Tu botón ya tiene height por defecto, pero esto asegura el layout
                          child: PrimaryButton(
                            label: 'Actualizar Perfil', // CORREGIDO: Usamos 'label'
                            isLoading: _isSaving,       // CORREGIDO: Usamos tu propiedad nativa de carga
                            onPressed: _saveProfile,    // Siempre pasamos la función, el botón manejará el bloqueo si isLoading es true
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Widget auxiliar para campos de solo lectura (Código limpio)
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
        ),
      ],
    );
  }
}