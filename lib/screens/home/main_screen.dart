import 'dart:async';

import 'dart:html' as html show window;
import 'package:provider/provider.dart';
import '../../providers/listing_provider.dart';
import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import '../../dto/listing/listing_create_dto.dart';
import '../../dto/listing/listing_dto.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/trade_provider.dart';
import '../../dto/trade/trade_status.dart';
import '../../dto/trade/trade_dto.dart';
import '../../providers/wallet_provider.dart';
import '../../dto/wallet/wallet_entry_dto.dart';
import '../../dto/wallet/wallet_entry_type.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:truekapp/screens/listing/pick_location_map_screen.dart';
//import 'dart:io'; // Para mostrar el archivo de imagen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  // Índice visible en el BottomNavigationBar (0..3 para la versión web demo)
  int _visibleNavIndex = 0;

  // Map desde el índice visible del nav hacia el índice real de la página
  // Mantiene la pantalla "Explorar" en el array _pages (índice 1), pero
  // la oculta de la barra inferior y remapea los índices visibles a las páginas:
  // visible 0 -> page 0 (Home)
  // visible 1 -> page 2 (Publicar)
  // visible 2 -> page 3 (Mensajes)
  // visible 3 -> page 4 (Billetera)
  final List<int> _navIndexToPage = [0, 2, 3, 4];

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
        //actions: [
        //IconButton(
        //tooltip: 'Debug token',
        //icon: const Icon(Icons.bug_report_outlined),
        //onPressed: () => Navigator.pushNamed(context, '/debug-token'),
        //),
        //], Revisarrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        // mostramos el índice visible (0..3) en la UI
        currentIndex: _visibleNavIndex,
        onTap: (i) => setState(() {
          // remapeamos al índice real de la página
          _visibleNavIndex = i;
          _currentIndex = _navIndexToPage[i];
        }),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          // BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Publicar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Billetera',
          ),
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
              // --- OPCIÓN PERFIL CORREGIDA ---
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Ver perfil'),
                onTap: () {
                  Navigator.pop(context); // Cierra el menú
                  Navigator.pushNamed(
                    context,
                    AppRoutes.profile,
                  ); // Va a la pantalla nueva
                },
              ),
              // --- OPCIÓN CERRAR SESIÓN (Se mantiene igual) ---
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () {
                  Navigator.pop(context);
                  auth.logout();
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

  // ← Aquí agregamos la variable para la ciudad
  String _currentCity = 'Cargando...';

  String _formatCoins(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
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

  Future<void> _updateCityFromPosition() async {
    if (_currentPosition == null) return;

    if (kIsWeb) {
      // Web: usamos Nominatim API
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=10&addressdetails=1';
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'TruekApp/1.0 (your_email@example.com)'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final city =
              data['address']?['city'] ??
              data['address']?['town'] ??
              data['address']?['village'] ??
              'Desconocida';
          setState(() => _currentCity = city);
        } else {
          setState(() => _currentCity = 'Desconocida');
        }
      } catch (_) {
        setState(() => _currentCity = 'Desconocida');
      }
    } else {
      // Mobile: usamos geocoding
      try {
        final placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        if (placemarks.isNotEmpty) {
          setState(
            () => _currentCity = placemarks.first.locality ?? 'Desconocida',
          );
        } else {
          setState(() => _currentCity = 'Desconocida');
        }
      } catch (_) {
        setState(() => _currentCity = 'Desconocida');
      }
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      if (kIsWeb) {
        final position = await html.window.navigator.geolocation
            .getCurrentPosition();
        if (!mounted) return;
        if (position.coords != null) {
          setState(
            () => _currentPosition = Position(
              latitude: position.coords!.latitude!.toDouble(),
              longitude: position.coords!.longitude!.toDouble(),
              timestamp: DateTime.now(),
              accuracy: 0.0,
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0, // obligatorio
              headingAccuracy: 0.0, // obligatorio
            ),
          );
          await _updateCityFromPosition();
          await _loadNearbyListings();
        }
      } else {
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
        await _updateCityFromPosition();
        await _loadNearbyListings();
      }
    } catch (_) {
      // Ignorar errores silenciosamente; la UI mostrará "Cerca de ti"
    }
  }

  Future<void> _loadNearbyListings() async {
    if (_currentPosition != null) {
      debugPrint('Posición actual: $_currentPosition');
      try {
        await Provider.of<ListingProvider>(
          context,
          listen: false,
        ).fetchNearbyListings(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radius: 25,
        );
        debugPrint(
          'Trueques cercanos encontrados: ${Provider.of<ListingProvider>(context, listen: false).nearbyListings.length}',
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando cercanos: $e')));
      }
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

        // Volvemos al padding estándar (sin el parche conservador de +100px)
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
                    children: [
                      Text(
                        'Ubicación: $_currentCity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'TrueCoin Balance',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Card(
                    color: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${auth.user?.trueCoinBalance ?? 120}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'TrueCoins',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
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
                  hintText: 'Buscar productos...',
                ),
                onSubmitted: (query) {
                  // Al presionar Enter, llamamos al fetch con el filtro 'q'
                  listingProvider.fetchCatalog(q: query);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Destacados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
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
                                  .listings[currentFeaturedIndex]
                                  .id,
                            );
                          },
                        ),
                      ),
              ),

              SizedBox(
                height: 290, // altura fija, ajusta a lo que necesites
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cerca de ti',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: listingProvider.isLoadingNearby
                          ? const Center(child: CircularProgressIndicator())
                          : listingProvider.nearbyListings.isEmpty
                          ? Center(
                              child: TextButton.icon(
                                onPressed: () async {
                                  await Provider.of<ListingProvider>(
                                    context,
                                    listen: false,
                                  ).fetchNearbyListings(
                                    latitude: _currentPosition?.latitude ?? 0,
                                    longitude: _currentPosition?.longitude ?? 0,
                                    radius: 25,
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text(
                                  'Sin resultados cerca de ti. Recargar',
                                ),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: listingProvider.nearbyListings.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, idx) {
                                final listing =
                                    listingProvider.nearbyListings[idx];
                                final distanceLabel = _formatDistance(listing);
                                return GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.listingDetail,
                                    arguments: listing.id,
                                  ),
                                  child: SizedBox(
                                    width: 300,
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 16 / 11,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(0),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.network(
                                                    listing.imageUrl,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder:
                                                        (
                                                          context,
                                                          child,
                                                          progress,
                                                        ) {
                                                          if (progress == null)
                                                            return child;
                                                          return Container(
                                                            color: Colors
                                                                .grey[200],
                                                            child: const Center(
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                          );
                                                        },
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stack,
                                                        ) => Container(
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .image_not_supported_outlined,
                                                              color:
                                                                  Colors.grey,
                                                              size: 36,
                                                            ),
                                                          ),
                                                        ),
                                                  ),
                                                  Positioned.fill(
                                                    child: DecoratedBox(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            Colors.transparent,
                                                            Colors.black
                                                                .withOpacity(
                                                                  0.55,
                                                                ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 12,
                                                    right: 12,
                                                    bottom: 12,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          listing.title,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.location_on,
                                                              size: 14,
                                                              color: Colors
                                                                  .white70,
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                distanceLabel ??
                                                                    'Cerca de ti',
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 12,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
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
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.monetization_on,
                                                  size: 18,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${_formatCoins(listing.trueCoinValue)} coins',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Recientes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),

              // --- CONTENIDO DINÁMICO (Recientes) ---
              listingProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: listingProvider.listings.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          Icon(
                                            Icons.monetization_on,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_formatCoins(listing.trueCoinValue)} coins',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              distanceLabel ?? 'Cerca de ti',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
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
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
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
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 42,
                    color: Colors.grey,
                  ),
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
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Cerca de ti',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: Colors.amber[300],
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_formatCoins(listing.trueCoinValue)} TrueCoins',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
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
          Text(
            'Explorar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
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

  // Image picker
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage; // Para guardar el archivo seleccionado

  // NUEVO: datos reales que mandaremos al backend
  Uint8List? _imageBytes; // bytes de la imagen
  String? _imageFileName; // nombre del archivo

  // Estado de carga
  bool _isLoading = false;

  // Geolocalización
  Position? _currentPosition;
  LatLng? _selectedLocation;

  Future<void> _pickLocation() async {
    LatLng initialLatLng;

    if (kIsWeb) {
      try {
        final position = await html.window.navigator.geolocation
            .getCurrentPosition();
        // Aquí usamos ! para asegurar que no es null
        final lat = position.coords?.latitude ?? -17.7833;
        final lng = position.coords?.longitude ?? -63.1821;
        initialLatLng = LatLng(lat.toDouble(), lng.toDouble());
      } catch (_) {
        initialLatLng = const LatLng(-17.7833, -63.1821);
      }
    } else {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        // Aquí position nunca será null en Mobile
        initialLatLng = LatLng(position.latitude, position.longitude);
      } catch (_) {
        initialLatLng = const LatLng(-17.7833, -63.1821);
      }
    }

    final LatLng? location = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationMapScreen(initialPosition: initialLatLng),
      ),
    );

    if (location != null) {
      setState(() => _selectedLocation = location);
    }
  }

  /// Lógica para seleccionar una imagen de la galería
  /// Lógica para seleccionar una imagen de la galería
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Leemos los bytes (funciona en Web y Mobile)
        final bytes = await image.readAsBytes();

        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
          _imageFileName = image.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al seleccionar imagen: ${e.toString()}"),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  /// Lógica para manejar la publicación
  Future<void> _handlePublish() async {
    // 1. Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar imagen
    if (_selectedImage == null ||
        _imageBytes == null ||
        _imageFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, seleccione una imagen"),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Obtener ubicación: primero seleccionada en mapa, luego ubicación actual
      final latLng =
          _selectedLocation ??
          (_currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : null);

      if (latLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se pudo obtener la ubicación."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 3. Parsear valores de los controladores
      final title = _titleController.text;
      final description = _descController.text;
      final trueCoinValue = double.tryParse(_valueController.text);

      if (trueCoinValue == null) {
        throw Exception("El valor de TrueCoins es inválido.");
      }

      // 4. Crear el DTO
      final dto = ListingCreateDto(
        title: title,
        description: description,
        trueCoinValue: trueCoinValue,
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        imageBytes: _imageBytes!,
        imageFileName: _imageFileName!,
      );

      // 5. Llamar al Provider
      await Provider.of<ListingProvider>(
        context,
        listen: false,
      ).createListing(dto);

      // 6. Éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Publicación creada con éxito"),
          backgroundColor: AppColors.successColor,
        ),
      );
      _clearForm();
    } catch (e) {
      // 7. Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: AppColors.errorColor,
        ),
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
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _imageFileName = null;
      _selectedLocation = null; // 🔥 Limpiar ubicación seleccionada
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
                decoration: const InputDecoration(
                  labelText: 'Valor (TrueCoins)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
                    if (_imageBytes == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Icon(
                          Icons.image_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _imageBytes!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _selectedImage == null
                            ? 'Seleccionar Imagen'
                            : 'Cambiar Imagen',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              // --- FIN DE MODIFICACIÓN DE UI ---

              // --- Botón para seleccionar ubicación ---
              ElevatedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.map),
                label: Text(
                  _selectedLocation == null
                      ? "Seleccionar ubicación en mapa"
                      : "Ubicación seleccionada",
                ),
              ),

              const SizedBox(height: 16),

              // Botón de carga dinámico
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handlePublish,
                      child: const Text('Publicar'),
                    ),
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

  // Filter state for trades list
  TradeFilter _filter = TradeFilter.All;

  // Helper predicates
  bool _isBuying(int currentUserId, TradeDto t) => t.requesterUserId == currentUserId;
  bool _isSelling(int currentUserId, TradeDto t) => t.ownerUserId == currentUserId;

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
    // Get current user id from AuthProvider
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.user?.id ?? -1;

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

        // 3. Filtros de pestañas (Todos / Comprando / Vendiendo)
        final filtered = tradeProvider.myTrades.where((t) {
          switch (_filter) {
            case TradeFilter.All:
              return true;
            case TradeFilter.Buying:
              return t.requesterUserId == currentUserId;
            case TradeFilter.Selling:
              return t.ownerUserId == currentUserId;
          }
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _buildFilterButton(TradeFilter.All, 'Todos'),
                  const SizedBox(width: 8),
                  _buildFilterButton(TradeFilter.Buying, 'Comprando'),
                  const SizedBox(width: 8),
                  _buildFilterButton(TradeFilter.Selling, 'Vendiendo'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final trade = filtered[index];
                  final isBuying = trade.requesterUserId == currentUserId;
                  final isSelling = trade.ownerUserId == currentUserId;

                  Widget roleChip() {
                    if (isBuying) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Comprando', style: TextStyle(color: Colors.green)),
                      );
                    } else if (isSelling) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Vendiendo', style: TextStyle(color: Colors.orange)),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  String roleSubtitle() {
                    if (isBuying) return 'Oferta enviada por ti';
                    if (isSelling) return 'Oferta recibida';
                    return trade.message ?? 'Ver detalles del trueque...';
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person_outline, color: Colors.white),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            roleChip(),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FutureBuilder<String?>(
                                future: tradeProvider.fetchListingTitle(trade.targetListingId),
                                initialData: tradeProvider.getCachedListingTitle(trade.targetListingId),
                                builder: (context, snapshot) {
                                  final title = snapshot.data ?? 'Trueque #${trade.id}';
                                  return Text(title, style: const TextStyle(fontWeight: FontWeight.w700));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(roleSubtitle(), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        _getStatusText(trade.status),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: _getStatusColor(trade.status),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.tradeChat, arguments: trade.id);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// Local enum for filtering trades
enum TradeFilter { All, Buying, Selling }

extension on _MessagesTabState {
  Widget _buildFilterButton(TradeFilter f, String label) {
    final selected = _filter == f;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? AppColors.primary.withOpacity(0.08) : null,
          side: BorderSide(color: selected ? AppColors.primary : Colors.grey.shade300),
        ),
        onPressed: () => setState(() => _filter = f),
        child: Text(label, style: TextStyle(color: selected ? AppColors.primary : Colors.black87)),
      ),
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
                    const Text(
                      'TrueCoin Balance',
                      style: TextStyle(color: Colors.white70),
                    ),
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
                  Text(
                    'Movimientos recientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
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
    final icon = _isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          _formatAmount(entry.amount),
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${_entryDescription(entry.type)} • ${_formatDate(entry.createdAt)}',
        ),
      ),
    );
  }
}
