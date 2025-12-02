import 'dart:async';
import 'dart:convert';
import 'dart:html' as html show window;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';
import '../../dto/listing/listing_create_dto.dart';
import '../../dto/listing/listing_dto.dart';
import '../../dto/trade/trade_dto.dart';
import '../../dto/trade/trade_status.dart';
import '../../dto/wallet/wallet_entry_dto.dart';
import '../../dto/wallet/wallet_entry_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/trade_provider.dart';
import '../../providers/wallet_provider.dart';
import '../listing/pick_location_map_screen.dart';
import '../p2p/p2p_market_screen.dart';
import '../wallet/wallet_screen.dart';
import '../../services/api_client.dart'; // Para llamar a la IA

/// Constantes de estilo para Main Screen - consistencia visual con Admin Panel
class _MainScreenStyle {
  // Colores
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color subtitleColor = Color(0xFF64748B);

  // Bordes y sombras
  static const double borderRadius = 16.0;
  static const double smallBorderRadius = 12.0;

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Spacing
  static const double pagePadding = 20.0;
  static const double sectionSpacing = 24.0;
  static const double itemSpacing = 16.0;

  // Tipografía
  static TextStyle get headingStyle => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF0F172A),
  );

  static TextStyle get sectionTitleStyle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF0F172A),
  );

  static TextStyle get bodyStyle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF475569),
  );

  static TextStyle get labelStyle => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: subtitleColor,
  );

  static TextStyle get valueStyle => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF0F172A),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Widget> get _navPages => [
    _HomeTab(),
    _AddItemTab(),
    _MessagesTab(),
    _WalletTab(),
    const P2PMarketScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _MainScreenStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor: _MainScreenStyle.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'TruekApp',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: const Color(0xFF0F172A),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _MainScreenStyle.softShadow,
          ),
          child: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
            onPressed: () => _showMenu(context, auth),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _navPages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_outlined,
                  Icons.home_rounded,
                  'Home',
                ),
                _buildNavItem(
                  1,
                  Icons.add_circle_outline,
                  Icons.add_circle_rounded,
                  'Publicar',
                ),
                _buildNavItem(
                  2,
                  Icons.chat_bubble_outline,
                  Icons.chat_bubble_rounded,
                  'Mensajes',
                ),
                _buildNavItem(
                  3,
                  Icons.account_balance_wallet_outlined,
                  Icons.account_balance_wallet_rounded,
                  'Billetera',
                ),
                _buildNavItem(
                  4,
                  Icons.swap_horiz_outlined,
                  Icons.swap_horiz_rounded,
                  'Mercado',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
        _fadeController.reset();
        _fadeController.forward();
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Menu items
                  _buildMenuItem(
                    icon: Icons.swap_horiz_rounded,
                    iconColor: AppColors.primary,
                    title: 'Mis trueques',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.tradeList);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Crear trueque',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.trade);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Divider(color: Colors.grey[200]),
                  ),
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Ver perfil',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Cerrar sesión',
                    onTap: () {
                      Navigator.pop(context);
                      auth.logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            // Breakpoints para responsive
            final isDesktop = screenWidth >= 1200;
            final isTablet = screenWidth >= 900 && screenWidth < 1200;

            // Padding: mínimo en desktop para que el banner ocupe todo el ancho
            final horizontalPadding = isDesktop
                ? 24.0
                : (isTablet ? 20.0 : _MainScreenStyle.pagePadding);
            // Reducir spacing vertical en desktop
            final sectionSpacing = isDesktop
                ? 20.0
                : (isTablet ? 22.0 : _MainScreenStyle.sectionSpacing);

            return Container(
              color: _MainScreenStyle.backgroundColor,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: _MainScreenStyle.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header banner - ocupa todo el ancho disponible
                    _buildHeader(auth),
                    SizedBox(height: sectionSpacing),

                    // Barra de búsqueda - ancho completo
                    _buildSearchBar(listingProvider),
                    SizedBox(height: sectionSpacing),

                    // Sección Destacados
                    _buildSectionTitle('Destacados', Icons.star_rounded),
                    const SizedBox(height: 12),
                    _buildFeaturedSection(
                      listingProvider,
                      currentFeaturedIndex,
                    ),

                    SizedBox(height: sectionSpacing),

                    // Sección Cerca de ti
                    _buildSectionTitle(
                      'Cerca de ti',
                      Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildNearbySection(listingProvider),

                    SizedBox(height: sectionSpacing),

                    // Sección Recientes
                    _buildSectionTitle('Recientes', Icons.access_time_rounded),
                    const SizedBox(height: 12),
                    _buildRecentGrid(listingProvider, screenWidth),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(_MainScreenStyle.borderRadius),
        boxShadow: _MainScreenStyle.elevatedShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentCity,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'TrueCoin Balance',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${auth.user?.trueCoinBalance ?? 0}',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'TrueCoins',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ListingProvider listingProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_MainScreenStyle.borderRadius),
        boxShadow: _MainScreenStyle.softShadow,
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
          hintText: 'Buscar productos...',
          hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_MainScreenStyle.borderRadius),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onSubmitted: (query) {
          listingProvider.fetchCatalog(q: query);
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title, style: _MainScreenStyle.sectionTitleStyle),
      ],
    );
  }

  Widget _buildFeaturedSection(
    ListingProvider listingProvider,
    int currentFeaturedIndex,
  ) {
    return SizedBox(
      height: 230,
      child: listingProvider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            )
          : listingProvider.listings.isEmpty
          ? _buildEmptyState(
              icon: Icons.star_outline_rounded,
              message: 'Sin destacados',
              onRefresh: () => listingProvider.fetchCatalog(),
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _FeaturedListingCard(
                key: ValueKey(
                  'featured-${listingProvider.listings[currentFeaturedIndex].id}-$currentFeaturedIndex',
                ),
                listing: listingProvider.listings[currentFeaturedIndex],
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.listingDetail,
                    arguments:
                        listingProvider.listings[currentFeaturedIndex].id,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required VoidCallback onRefresh,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_MainScreenStyle.borderRadius),
        boxShadow: _MainScreenStyle.softShadow,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Recargar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbySection(ListingProvider listingProvider) {
    return SizedBox(
      height: 260,
      child: listingProvider.isLoadingNearby
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            )
          : listingProvider.nearbyListings.isEmpty
          ? _buildEmptyState(
              icon: Icons.location_off_rounded,
              message: 'Sin resultados cerca de ti',
              onRefresh: () async {
                await Provider.of<ListingProvider>(
                  context,
                  listen: false,
                ).fetchNearbyListings(
                  latitude: _currentPosition?.latitude ?? 0,
                  longitude: _currentPosition?.longitude ?? 0,
                  radius: 25,
                );
              },
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: listingProvider.nearbyListings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, idx) {
                final listing = listingProvider.nearbyListings[idx];
                final distanceLabel = _formatDistance(listing);
                return _buildNearbyCard(listing, distanceLabel);
              },
            ),
    );
  }

  Widget _buildNearbyCard(ListingDto listing, String? distanceLabel) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.listingDetail,
        arguments: listing.id,
      ),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_MainScreenStyle.borderRadius),
          boxShadow: _MainScreenStyle.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    listing.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                          size: 36,
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
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                distanceLabel ?? 'Cerca de ti',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12,
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
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.monetization_on_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_formatCoins(listing.trueCoinValue)} coins',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF1E293B),
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

  Widget _buildRecentGrid(ListingProvider listingProvider, double screenWidth) {
    if (listingProvider.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
      );
    }

    // Calcular columnas según breakpoints
    // AspectRatio ajustado para tipografía más grande
    int crossAxisCount;
    double childAspectRatio;
    double spacing;

    if (screenWidth >= 1200) {
      // Desktop: 4 columnas
      crossAxisCount = 4;
      childAspectRatio = 0.72;
      spacing = 16;
    } else if (screenWidth >= 900) {
      // Tablet: 3 columnas
      crossAxisCount = 3;
      childAspectRatio = 0.70;
      spacing = 14;
    } else {
      // Mobile: 2 columnas
      crossAxisCount = 2;
      childAspectRatio = 0.68;
      spacing = 12;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listingProvider.listings.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final listing = listingProvider.listings[index];
        final distanceLabel = _formatDistance(listing);
        return _buildRecentCard(listing, distanceLabel);
      },
    );
  }

  Widget _buildRecentCard(ListingDto listing, String? distanceLabel) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.listingDetail,
          arguments: listing.id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_MainScreenStyle.borderRadius),
          boxShadow: _MainScreenStyle.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen con aspect ratio fijo
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  listing.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stack) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Contenido compacto - sin espacio extra
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF1E293B),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${_formatCoins(listing.trueCoinValue)} coins',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          distanceLabel ?? 'Cerca de ti',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[500],
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_MainScreenStyle.borderRadius),
          boxShadow: _MainScreenStyle.elevatedShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_MainScreenStyle.borderRadius),
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
                      color: Colors.grey[100],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[100],
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
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
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
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF9500),
                              const Color(0xFFFF6B00),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9500).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'DESTACADO',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cerca de ti',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.monetization_on_rounded,
                                color: Colors.amber[300],
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatCoins(listing.trueCoinValue)} TrueCoins',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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

  // --- LÓGICA IA ---
  bool _isGeneratingAi = false;

  Future<void> _generateDescriptionWithAI() async {
    final text = _descController.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Escribe al menos una idea básica (min. 5 letras)."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGeneratingAi = true);

    try {
      // Llamamos al servicio (asegúrate de tener el import de api_client.dart arriba)
      final newText = await ApiClient().enhanceText(text);

      setState(() {
        _descController.text = newText;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Descripción mejorada con IA! ✨"),
            backgroundColor: Colors.indigo,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al generar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAi = false);
    }
  }

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
    return Container(
      color: _MainScreenStyle.backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(_MainScreenStyle.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text('Nueva Publicación', style: _MainScreenStyle.headingStyle),
              const SizedBox(height: 8),
              Text(
                'Comparte algo para intercambiar',
                style: _MainScreenStyle.bodyStyle,
              ),
              const SizedBox(height: _MainScreenStyle.sectionSpacing),

              // Formulario en tarjeta
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    _MainScreenStyle.borderRadius,
                  ),
                  boxShadow: _MainScreenStyle.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo Título
                    Text('Título', style: _MainScreenStyle.labelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.inter(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: '¿Qué estás ofreciendo?',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _MainScreenStyle.smallBorderRadius,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _MainScreenStyle.smallBorderRadius,
                          ),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _MainScreenStyle.smallBorderRadius,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'El título es requerido'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // --- SECCIÓN DESCRIPCIÓN (MODIFICADA CON IA) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Descripción', style: _MainScreenStyle.labelStyle),
                        // Botón Mágico
                        TextButton.icon(
                          onPressed: _isGeneratingAi ? null : _generateDescriptionWithAI,
                          icon: _isGeneratingAi
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                          label: Text(
                            _isGeneratingAi ? "Mejorando..." : "Mejorar con IA",
                            style: GoogleFonts.inter(
                              color: _isGeneratingAi ? Colors.grey : AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      style: GoogleFonts.inter(fontSize: 15),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe el artículo en detalle...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _MainScreenStyle.smallBorderRadius,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _MainScreenStyle.smallBorderRadius,
                          ),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _MainScreenStyle.smallBorderRadius,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo Valor
                    Text(
                      'Valor (TrueCoins)',
                      style: _MainScreenStyle.labelStyle,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _valueController,
                      style: GoogleFonts.inter(fontSize: 15),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.monetization_on_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _MainScreenStyle.smallBorderRadius,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _MainScreenStyle.smallBorderRadius,
                          ),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _MainScreenStyle.smallBorderRadius,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'El valor es requerido'
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: _MainScreenStyle.sectionSpacing),

              // Imagen
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    _MainScreenStyle.borderRadius,
                  ),
                  boxShadow: _MainScreenStyle.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.image_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Imagen del artículo',
                          style: _MainScreenStyle.sectionTitleStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: _imageBytes == null ? 160 : 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(
                            _MainScreenStyle.smallBorderRadius,
                          ),
                          border: Border.all(
                            color: _imageBytes == null
                                ? Colors.grey[300]!
                                : AppColors.primary,
                            width: _imageBytes == null ? 1 : 2,
                            style: _imageBytes == null
                                ? BorderStyle.solid
                                : BorderStyle.solid,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _imageBytes == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 36,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Toca para seleccionar imagen',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(_imageBytes!, fit: BoxFit.cover),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: _pickImage,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: _MainScreenStyle.sectionSpacing),

              // Ubicación
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    _MainScreenStyle.borderRadius,
                  ),
                  boxShadow: _MainScreenStyle.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Ubicación',
                          style: _MainScreenStyle.sectionTitleStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickLocation,
                      borderRadius: BorderRadius.circular(
                        _MainScreenStyle.smallBorderRadius,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(
                            _MainScreenStyle.smallBorderRadius,
                          ),
                          border: Border.all(
                            color: _selectedLocation != null
                                ? const Color(0xFF3B82F6)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedLocation == null
                                  ? Icons.add_location_alt_outlined
                                  : Icons.check_circle_rounded,
                              color: _selectedLocation == null
                                  ? Colors.grey[500]
                                  : const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedLocation == null
                                    ? 'Seleccionar ubicación en mapa'
                                    : 'Ubicación seleccionada',
                                style: GoogleFonts.inter(
                                  color: _selectedLocation == null
                                      ? Colors.grey[600]
                                      : const Color(0xFF3B82F6),
                                  fontWeight: _selectedLocation == null
                                      ? FontWeight.w400
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botón Publicar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _handlePublish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _MainScreenStyle.borderRadius,
                            ),
                          ),
                          shadowColor: AppColors.primary.withOpacity(0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.publish_rounded),
                            const SizedBox(width: 12),
                            Text(
                              'Publicar',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),
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
    Provider.of<TradeProvider>(context, listen: false).fetchMyTrades();
  }

  TradeFilter _filter = TradeFilter.All;

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

  Color _getStatusColor(TradeStatus status) {
    switch (status) {
      case TradeStatus.Pending:
        return const Color(0xFFFF9500);
      case TradeStatus.Accepted:
        return const Color(0xFF3B82F6);
      case TradeStatus.Completed:
        return AppColors.primary;
      case TradeStatus.Rejected:
      case TradeStatus.Cancelled:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.user?.id ?? -1;

    return Consumer<TradeProvider>(
      builder: (context, tradeProvider, child) {
        if (tradeProvider.isLoading) {
          return Container(
            color: _MainScreenStyle.backgroundColor,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (tradeProvider.myTrades.isEmpty) {
          return Container(
            color: _MainScreenStyle.backgroundColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sin conversaciones',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tus trueques aparecerán aquí',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

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

        return Container(
          color: _MainScreenStyle.backgroundColor,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(_MainScreenStyle.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mensajes', style: _MainScreenStyle.headingStyle),
                    const SizedBox(height: 4),
                    Text(
                      '${tradeProvider.myTrades.length} conversaciones',
                      style: _MainScreenStyle.bodyStyle,
                    ),
                  ],
                ),
              ),
              // Filtros
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _MainScreenStyle.pagePadding,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      _MainScreenStyle.smallBorderRadius,
                    ),
                    boxShadow: _MainScreenStyle.softShadow,
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip(TradeFilter.All, 'Todos'),
                      _buildFilterChip(TradeFilter.Buying, 'Comprando'),
                      _buildFilterChip(TradeFilter.Selling, 'Vendiendo'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Lista de trades
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _MainScreenStyle.pagePadding,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final trade = filtered[index];
                    return _buildTradeCard(trade, currentUserId, tradeProvider);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(TradeFilter f, String label) {
    final selected = _filter == f;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTradeCard(
    TradeDto trade,
    int currentUserId,
    TradeProvider tradeProvider,
  ) {
    final isBuying = trade.requesterUserId == currentUserId;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.tradeChat, arguments: trade.id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_MainScreenStyle.borderRadius),
          boxShadow: _MainScreenStyle.softShadow,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isBuying
                      ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                      : [const Color(0xFFF97316), const Color(0xFFEA580C)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isBuying ? Icons.shopping_bag_outlined : Icons.sell_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isBuying
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFF97316))
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isBuying ? 'Comprando' : 'Vendiendo',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isBuying
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFF97316),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(trade.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(trade.status),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(trade.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String?>(
                    future: tradeProvider.fetchListingTitle(
                      trade.targetListingId,
                    ),
                    initialData: tradeProvider.getCachedListingTitle(
                      trade.targetListingId,
                    ),
                    builder: (context, snapshot) {
                      final title = snapshot.data ?? 'Trueque #${trade.id}';
                      return Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBuying ? 'Oferta enviada por ti' : 'Oferta recibida',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// Local enum for filtering trades
enum TradeFilter { All, Buying, Selling }

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

  void _openWallet(BuildContext context, WalletOperationType type) {
    Navigator.pushNamed(context, AppRoutes.wallet, arguments: type);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final wallet = walletProvider.wallet;
        final entries = wallet?.entries ?? [];

        if (walletProvider.isLoading && wallet == null) {
          return Container(
            color: _MainScreenStyle.backgroundColor,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          );
        }

        return Container(
          color: _MainScreenStyle.backgroundColor,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: walletProvider.fetchWallet,
            child: ListView(
              padding: const EdgeInsets.all(_MainScreenStyle.pagePadding),
              children: [
                // Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      _MainScreenStyle.borderRadius,
                    ),
                    boxShadow: _MainScreenStyle.elevatedShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TrueCoin Balance',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCoins(wallet?.balance ?? 0),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'TrueCoins',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildWalletButton(
                              icon: Icons.add_rounded,
                              label: 'Recargar',
                              onTap: () => _openWallet(
                                context,
                                WalletOperationType.deposit,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildWalletButton(
                              icon: Icons.arrow_downward_rounded,
                              label: 'Retirar',
                              onTap: () => _openWallet(
                                context,
                                WalletOperationType.withdraw,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _MainScreenStyle.sectionSpacing),

                // Movimientos section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Movimientos recientes',
                      style: _MainScreenStyle.sectionTitleStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (walletProvider.isLoading)
                  LinearProgressIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    minHeight: 3,
                  ),

                if (entries.isEmpty && !walletProvider.isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        _MainScreenStyle.borderRadius,
                      ),
                      boxShadow: _MainScreenStyle.softShadow,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sin movimientos aún',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...entries.map((entry) => _WalletEntryTile(entry: entry)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalletButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
      case WalletEntryType.P2PDeposit:
        return 'Recarga P2P';
      case WalletEntryType.P2PWithdrawal:
        return 'Retiro P2P';
      case WalletEntryType.Adjustment:
        return 'Ajuste de saldo';
    }
  }

  IconData _getTypeIcon(WalletEntryType type) {
    switch (type) {
      case WalletEntryType.Deposit:
      case WalletEntryType.P2PDeposit:
        return Icons.add_circle_rounded;
      case WalletEntryType.Withdrawal:
      case WalletEntryType.P2PWithdrawal:
        return Icons.remove_circle_rounded;
      case WalletEntryType.TradeSent:
        return Icons.send_rounded;
      case WalletEntryType.TradeReceived:
        return Icons.call_received_rounded;
      case WalletEntryType.Adjustment:
        return Icons.tune_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _isPositive
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_MainScreenStyle.borderRadius),
        boxShadow: _MainScreenStyle.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_getTypeIcon(entry.type), color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _entryDescription(entry.type),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(entry.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatAmount(entry.amount),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
