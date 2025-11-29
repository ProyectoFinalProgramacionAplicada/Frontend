import 'package:image_picker/image_picker.dart'; // Asegúrate de tener esta dependencia
import 'package:provider/provider.dart';
import '../../core/app_export.dart';
import '../../dto/auth/user_update_dto.dart';
import '../../dto/listing/listing_dto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/phone_input_field.dart';
import '../../widgets/phone_display_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<ListingDto>> _myListingsFuture;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.id;
    if (userId != null) {
      _myListingsFuture = Provider.of<ListingProvider>(
        context,
        listen: false,
      ).getListingsByOwner(userId);
    } else {
      _myListingsFuture = Future.value([]);
    }
  }

  // --- LÓGICA DE EDICIÓN ---

  // 1. Subir Foto
  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final fileName = image.name;

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Subiendo imagen...")));

      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).updateAvatar(bytes, fileName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Foto actualizada!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // 2. Editar Datos Básicos
  void _showEditProfileDialog(
    BuildContext context,
    String? currentName,
    String? currentPhone,
  ) {
    final nameController = TextEditingController(text: currentName);
    String phoneValue = currentPhone ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Perfil"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nombre Completo"),
              ),
              const SizedBox(height: 16),
              PhoneInputField(
                label: 'Teléfono',
                initialValue: currentPhone,
                onChanged: (phone) {
                  phoneValue = phone;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).updateProfile(
                  UserUpdateDto(
                    displayName: nameController.text.trim(),
                    phone: phoneValue.isEmpty ? null : phoneValue,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Perfil actualizado"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // 3. Cambiar Contraseña
  void _showChangePasswordDialog(BuildContext context) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cambiar Contraseña"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassController,
              decoration: const InputDecoration(labelText: "Contraseña Actual"),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPassController,
              decoration: const InputDecoration(labelText: "Nueva Contraseña"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).changePassword(
                  oldPassController.text,
                  newPassController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Contraseña actualizada exitosamente"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Cambiar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Sin sesión")));
    }

    final fullAvatarUrl = user.avatarUrl != null
        ? '${AppConstants.apiBaseUrl}${user.avatarUrl}'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        actions: [
          // Botón Editar Datos
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Editar Datos",
            onPressed: () =>
                _showEditProfileDialog(context, user.displayName, user.phone),
          ),
          // Botón Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: "Cerrar Sesión",
            onPressed: () {
              authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- SECCIÓN 1: AVATAR Y NOMBRE ---
            Center(
              child: Stack(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _pickAndUploadImage, // Tocar para cambiar foto
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: fullAvatarUrl != null
                          ? NetworkImage(fullAvatarUrl)
                          : null,
                      child: fullAvatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  ),
                  // Icono de cámara
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(blurRadius: 3, color: Colors.black26),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              user.displayName ?? "Sin Nombre",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(user.email ?? "", style: TextStyle(color: Colors.grey[600])),

            // Teléfono con bandera y formato elegante
            if (user.phone != null && user.phone!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: PhoneDisplayWidget(phone: user.phone, compact: true),
              ),

            // Botón Cambiar Contraseña
            TextButton.icon(
              onPressed: () => _showChangePasswordDialog(context),
              icon: const Icon(Icons.lock_outline, size: 16),
              label: const Text("Cambiar Contraseña"),
            ),

            const SizedBox(height: 20),

            // --- SECCIÓN 2: BALANCE ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Balance", style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 4),
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                  Text(
                    "${user.trueCoinBalance.toStringAsFixed(2)} TC",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- SECCIÓN 3: MIS PRODUCTOS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Mis Publicaciones",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Grid de Productos
            FutureBuilder<List<ListingDto>>(
              future: _myListingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final listings = snapshot.data ?? [];
                if (listings.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(30),
                    child: const Text(
                      "No tienes productos activos.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final item = listings[index];
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.listingDetail,
                        arguments: item.id,
                      ),
                      child: Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey[200]),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${item.trueCoinValue} TC",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
