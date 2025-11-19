import 'dart:async';

import 'package:provider/provider.dart';
import '../../providers/listing_provider.dart';
import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import '../../dto/listing/listing_create_dto.dart';
import '../../dto/listing/listing_dto.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/trade_provider.dart';
import '../../dto/trade/trade_status.dart';
import '../../providers/wallet_provider.dart';
import '../../dto/wallet/wallet_entry_dto.dart';
import '../../dto/wallet/wallet_entry_type.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io'; // Para mostrar el archivo de imagen


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        _HomeTab(),
        _BrowseTab(),
        _AddItemTab(),
        _MessagesTab(),
        _WalletTab(),
      ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('TruekApp'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showMenu(context, auth),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Publicar'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Billetera'),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Ver perfil'),
                onTap: () {
                  Navigator.pop(context);
                  // Por ahora solo muestra diálogo sencillo
                  showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: const Text('Perfil'),
                            content: Text(auth.user != null
                                ? 'Usuario: ${auth.user!.email}'
                                : 'No hay usuario cargado'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cerrar'))
                            ],
                          ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () {
                  Navigator.pop(context);
                  auth.logout();
                  // Volver al login
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Tabs ---
class _HomeTab extends StatefulWidget {
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _searchController = TextEditingController();
  Timer? _featuredTimer;
  int _featuredIndex = 0;
  ListingProvider? _listingProvider;
  Position? _currentPosition;

  String _formatCoins(double value) {
    return value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  String? _formatDistance(ListingDto listing) {
    if (_currentPosition == null) return null;
    final meters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      listing.latitude,
      listing.longitude,
    );
    if (meters.isNaN) return null;
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
    }
    return '${meters.round()} m';
  }

  @override
  void initState() {
    super.initState();

    // CORRECTO: Ejecuta la lógica después del primer build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ListingProvider>(context, listen: false).fetchCatalog();
      _loadCurrentLocation();
    });
  }

  Future<void> _loadCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;
      setState(() => _currentPosition = position);
    } catch (_) {
      // Ignorar errores silenciosamente; la UI mostrará "Cerca de ti"
    }
  }

  void _startFeaturedTimer() {
    if (_featuredTimer != null) return;
    _featuredTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final provider = _listingProvider;
      if (!mounted || provider == null) return;
      final total = provider.listings.length;
      if (total <= 1) return;
      setState(() {
        _featuredIndex = (_featuredIndex + 1) % total;
      });
    });
  }

  void _stopFeaturedTimer() {
    _featuredTimer?.cancel();
    _featuredTimer = null;
  }

  @override
  void dispose() {
    _featuredTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Usamos Consumer para que la UI reaccione a los cambios del ListingProvider
    return Consumer<ListingProvider>(
      builder: (context, listingProvider, child) {
        _listingProvider = listingProvider;

        final totalFeatured = listingProvider.listings.length;
        if (totalFeatured <= 1) {
          _stopFeaturedTimer();
        } else {
          _startFeaturedTimer();
        }

        final int currentFeaturedIndex = totalFeatured == 0
            ? 0
            : _featuredIndex % totalFeatured;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // (Esta parte del balance se mantiene igual)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Ubicación: Ciudad de Ejemplo',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('TrueCoin Balance',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Card(
                    color: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          Text('${auth.user?.trueCoinBalance ?? 120}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          const Text('TrueCoins',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TextField de Búsqueda funcional
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar productos...'),
                onSubmitted: (query) {
                  // Al presionar Enter, llamamos al fetch con el filtro 'q'
                  listingProvider.fetchCatalog(q: query);
                },
              ),
              const SizedBox(height: 16),
              const Text('Destacados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              // --- CONTENIDO DINÁMICO (Destacados) ---
              SizedBox(
                height: 230,
                child: listingProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : listingProvider.listings.isEmpty
                        ? Center(
                            child: TextButton.icon(
                              onPressed: () => listingProvider.fetchCatalog(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Sin destacados. Recargar'),
                            ),
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _FeaturedListingCard(
                              key: ValueKey(
                                'featured-${listingProvider.listings[currentFeaturedIndex].id}-$currentFeaturedIndex',
                              ),
                              listing:
                                  listingProvider.listings[currentFeaturedIndex],
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.listingDetail,
                                  arguments: listingProvider
                                      .listings[currentFeaturedIndex].id,
                                );
                              },
                            ),
                          ),
              ),

              const SizedBox(height: 16),
              const Text('Recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              // --- CONTENIDO DINÁMICO (Recientes) ---
              listingProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: listingProvider.listings.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        final listing = listingProvider.listings[index];
                        final distanceLabel = _formatDistance(listing);
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.listingDetail,
                              arguments: listing.id,
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 11,
                                  child: Ink.image(
                                    image: NetworkImage(listing.imageUrl),
                                    fit: BoxFit.cover,
                                    child: Container(),
                                    onImageError: (_, __) {},
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.monetization_on,
                                              size: 18,
                                              color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_formatCoins(listing.trueCoinValue)} coins',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              distanceLabel ?? 'Cerca de ti',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _FeaturedListingCard extends StatelessWidget {
  final ListingDto listing;
  final VoidCallback onTap;

  const _FeaturedListingCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  String _formatCoins(double value) {
    return value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.network(
                listing.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported_outlined,
                      size: 42, color: Colors.grey),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Cerca de ti',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on,
                                color: Colors.amber[300], size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${_formatCoins(listing.trueCoinValue)} TrueCoins',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _BrowseTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.explore, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('Explorar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AddItemTab extends StatefulWidget {
  @override
  State<_AddItemTab> createState() => _AddItemTabState();
}

class _AddItemTabState extends State<_AddItemTab> {
  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  
  // MODIFICADO: Eliminamos _imageUrlController y añadimos _selectedImage
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage; // Para guardar el archivo seleccionado

  // Estado de carga
  bool _isLoading = false;

  /// Lógica para seleccionar una imagen de la galería
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error al seleccionar imagen: ${e.toString()}"),
            backgroundColor: AppColors.errorColor),
      );
    }
  }

  /// Lógica para manejar la publicación
  Future<void> _handlePublish() async {
    // 1. Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return; // Si hay errores, no continuar
    }

    // MODIFICADO: Validación de imagen
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Por favor, seleccione una imagen"),
            backgroundColor: AppColors.errorColor),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Obtener la ubicación del dispositivo (sin cambios)
      Position position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception("Permiso de ubicación denegado.");
          }
        }
        if (permission == LocationPermission.deniedForever) {
          throw Exception("Permiso de ubicación denegado permanentemente.");
        }
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium);
      } catch (e) {
        throw Exception("Error al obtener ubicación: ${e.toString()}");
      }

      // 3. Parsear valores de los controladores
      final title = _titleController.text;
      final description = _descController.text;
      // MODIFICADO: Usamos la ruta (path) de la imagen seleccionada
      final imagePath = _selectedImage!.path; 
      final trueCoinValue = double.tryParse(_valueController.text);

      if (trueCoinValue == null) {
        throw Exception("El valor de TrueCoins es inválido.");
      }

      // 4. Crear el DTO (Data Transfer Object)
      final dto = ListingCreateDto(
        title: title,
        description: description,
        trueCoinValue: trueCoinValue,
        // MODIFICADO: Pasamos la ruta del archivo
        imagePath: imagePath, 
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // 5. Llamar al Provider
      await Provider.of<ListingProvider>(context, listen: false)
          .createListing(dto);

      // 6. Éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Publicación creada con éxito"),
            backgroundColor: AppColors.successColor),
      );
      _clearForm();
    } catch (e) {
      // 7. Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppColors.errorColor),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Limpia los campos del formulario después de publicar
  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descController.clear();
    _valueController.clear();
    // MODIFICADO: Limpiamos la imagen
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _valueController.dispose();
    // MODIFICADO: Ya no necesitamos el _imageUrlController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'El título es requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _valueController,
                decoration:
                    const InputDecoration(labelText: 'Valor (TrueCoins)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (v) =>
                    v == null || v.isEmpty ? 'El valor es requerido' : null,
              ),
              const SizedBox(height: 16),

              // --- MODIFICADO: UI para seleccionar imagen ---
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_selectedImage == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Icon(Icons.image_outlined,
                            size: 60, color: Colors.grey),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb // <--- CORRECCIÓN PROFESIONAL AQUÍ
                              ? Image.network(
                                  _selectedImage!.path,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_selectedImage!.path),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_selectedImage == null
                          ? 'Seleccionar Imagen'
                          : 'Cambiar Imagen'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              // --- FIN DE MODIFICACIÓN DE UI ---

              const SizedBox(height: 16),

              // Botón de carga dinámico
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handlePublish,
                      child: const Text('Publicar'),
                    )
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesTab extends StatefulWidget {
  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  @override
  void initState() {
    super.initState();
    // Cargar los trades del usuario al iniciar la pestaña
    // Usamos 'listen: false' en initState
    Provider.of<TradeProvider>(context, listen: false).fetchMyTrades();
  }

  // --- Helpers para mostrar el estado del Trueque ---

  // Devuelve un texto legible para el estado
  String _getStatusText(TradeStatus status) {
    switch (status) {
      case TradeStatus.Pending:
        return "Pendiente";
      case TradeStatus.Accepted:
        return "Aceptado";
      case TradeStatus.Rejected:
        return "Rechazado";
      case TradeStatus.Completed:
        return "Completado";
      case TradeStatus.Cancelled:
        return "Cancelado";
    }
  }

  // Devuelve un color para el chip de estado
  Color _getStatusColor(TradeStatus status) {
    switch (status) {
      case TradeStatus.Pending:
        return Colors.orangeAccent;
      case TradeStatus.Accepted:
        return Colors.blueAccent;
      case TradeStatus.Completed:
        return Colors.green;
      case TradeStatus.Rejected:
      case TradeStatus.Cancelled:
        return Colors.redAccent;
    }
  }

  // --- Fin de Helpers ---

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para que la UI reaccione a los cambios del TradeProvider
    return Consumer<TradeProvider>(
      builder: (context, tradeProvider, child) {
        // 1. Manejar estado de carga
        if (tradeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Manejar estado vacío
        if (tradeProvider.myTrades.isEmpty) {
          return const Center(
            child: Text(
              "No tienes conversaciones de trueques.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // 3. Mostrar la lista de trueques (conversaciones)
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tradeProvider.myTrades.length,
          itemBuilder: (context, index) {
            // Obtenemos el trade específico
            final trade = tradeProvider.myTrades[index];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person_outline,
                    color: Colors.white), // Placeholder
              ),
              title: Text('Trueque #${trade.id}'),
              subtitle: Text(
                trade.message ?? 'Ver detalles del trueque...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Usamos un Chip para el estado
              trailing: Chip(
                label: Text(
                  _getStatusText(trade.status),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: _getStatusColor(trade.status),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              ),
              onTap: () {
                // --- PRÓXIMO PASO ---
                // Aquí es donde debemos navegar a una nueva pantalla de chat.
                // Como aún no existe, mostramos un SnackBar temporal.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'TODO: Abrir pantalla de chat para Trade ID: ${trade.id}'),
                  ),
                );
                // El código final sería:
                // Navigator.pushNamed(context, AppRoutes.tradeChat, arguments: trade.id);
              },
            );
          },
        );
      },
    );
  }
}
class _WalletTab extends StatefulWidget {
  @override
  State<_WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<_WalletTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchWallet();
    });
  }

  String _formatCoins(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final wallet = walletProvider.wallet;
        final entries = wallet?.entries ?? [];

        if (walletProvider.isLoading && wallet == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: walletProvider.fetchWallet,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TrueCoin Balance',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      _formatCoins(wallet?.balance ?? 0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.wallet);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Recargar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Movimientos recientes',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              if (walletProvider.isLoading)
                const LinearProgressIndicator(minHeight: 2),
              if (entries.isEmpty && !walletProvider.isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  alignment: Alignment.center,
                  child: const Text(
                    'No hay movimientos registrados todavía.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...entries.map((entry) => _WalletEntryTile(entry: entry)),
            ],
          ),
        );
      },
    );
  }
}

class _WalletEntryTile extends StatelessWidget {
  final WalletEntryDto entry;

  const _WalletEntryTile({required this.entry});

  bool get _isPositive => entry.amount >= 0;

  String _formatAmount(double value) {
    final absValue = value.abs();
    final formatted = absValue % 1 == 0
        ? absValue.toStringAsFixed(0)
        : absValue.toStringAsFixed(2);
    final sign = _isPositive ? '+' : '-';
    return '$sign$formatted TrueCoins';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  String _entryDescription(WalletEntryType type) {
    switch (type) {
      case WalletEntryType.Deposit:
        return 'Depósito';
      case WalletEntryType.Withdrawal:
        return 'Retiro';
      case WalletEntryType.TradeSent:
        return 'Trueque enviado';
      case WalletEntryType.TradeReceived:
        return 'Trueque recibido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _isPositive ? Colors.green : Colors.red;
    final icon = _isPositive ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          _formatAmount(entry.amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text('${_entryDescription(entry.type)} • ${_formatDate(entry.createdAt)}'),
      ),
    );
  }
}
