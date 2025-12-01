import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:truekapp/screens/profile/seller_profile_screen.dart';
import '../../providers/listing_provider.dart';
import '../../providers/trade_provider.dart';
import '../../dto/listing/listing_dto.dart';
import '../../dto/trade/trade_create_dto.dart';
import '../../core/app_export.dart';
import '../../screens/trade/trade_create_screen.dart';

/// Constantes de estilo para ListingDetail - consistencia visual con Login/Register
class _ListingDetailStyle {
  // Colores
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color primaryColor = Color(0xFF166534);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

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
  static const double pagePadding = 24.0;
  static const double sectionSpacing = 24.0;
  static const double itemSpacing = 16.0;

  // Tipografía
  static TextStyle get headingStyle => GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get titleStyle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get bodyStyle => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF475569),
    height: 1.6,
  );

  static TextStyle get labelStyle => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static TextStyle get priceStyle => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: primaryColor,
  );
}

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  int? _listingId;
  ListingDto? _listing;
  bool _isLoading = true;
  bool _isCreatingTrade = false;
  final _messageController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtenemos el ID pasado como argumento
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is int && _listingId == null) {
      _listingId = args;
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    if (_listingId == null) return;
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<ListingProvider>(context, listen: false);
      _listing = await provider.fetchListingById(_listingId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalle: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCreateTrade() async {
    if (_listingId == null) return;
    final tradeProvider = Provider.of<TradeProvider>(context, listen: false);

    // If provider already has a pending create for this listing, avoid sending again
    if (tradeProvider.isCreatePendingFor(_listingId!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya hay una oferta en proceso para este producto.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() => _isCreatingTrade = true);

    final dto = TradeCreateDto(
      targetListingId: _listingId!,
      message: _messageController.text.trim().isEmpty
          ? "Hola, estoy interesado en tu '${_listing!.title}'"
          : _messageController.text.trim(),
    );

    try {
      await tradeProvider.createTrade(dto);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Oferta enviada!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar oferta: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingTrade = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ListingDetailStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _ListingDetailStyle.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _ListingDetailStyle.softShadow,
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: _ListingDetailStyle.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: _isLoading
            ? null
            : Text(
                _listing?.title ?? 'Detalle',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _ListingDetailStyle.textPrimary,
                ),
              ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _ListingDetailStyle.primaryColor,
                strokeWidth: 3,
              ),
            )
          : _listing == null
          ? _buildErrorState()
          : _buildListingDetails(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _ListingDetailStyle.cardColor,
          borderRadius: BorderRadius.circular(_ListingDetailStyle.borderRadius),
          boxShadow: _ListingDetailStyle.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 16),
            Text('No se pudo cargar', style: _ListingDetailStyle.titleStyle),
            const SizedBox(height: 8),
            Text(
              'La publicación no está disponible.',
              style: _ListingDetailStyle.labelStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _fetchDetails,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                foregroundColor: _ListingDetailStyle.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: _ListingDetailStyle.pagePadding,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen principal con bordes redondeados
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                _ListingDetailStyle.borderRadius,
              ),
              boxShadow: _ListingDetailStyle.elevatedShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                _ListingDetailStyle.borderRadius,
              ),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  _listing!.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _ListingDetailStyle.primaryColor,
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: _ListingDetailStyle.sectionSpacing),

          // Card de información principal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _ListingDetailStyle.cardColor,
              borderRadius: BorderRadius.circular(
                _ListingDetailStyle.borderRadius,
              ),
              boxShadow: _ListingDetailStyle.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(_listing!.title, style: _ListingDetailStyle.headingStyle),
                const SizedBox(height: 16),

                // Precio con badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _ListingDetailStyle.primaryColor.withOpacity(0.1),
                        _ListingDetailStyle.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      _ListingDetailStyle.smallBorderRadius,
                    ),
                    border: Border.all(
                      color: _ListingDetailStyle.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _ListingDetailStyle.primaryColor.withOpacity(
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.monetization_on_rounded,
                          color: _ListingDetailStyle.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_listing!.trueCoinValue.toStringAsFixed(_listing!.trueCoinValue % 1 == 0 ? 0 : 2)} TrueCoins',
                        style: _ListingDetailStyle.priceStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: _ListingDetailStyle.itemSpacing),

          // Tarjeta del vendedor
          _buildSellerCard(),

          const SizedBox(height: _ListingDetailStyle.itemSpacing),

          // Descripción
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _ListingDetailStyle.cardColor,
              borderRadius: BorderRadius.circular(
                _ListingDetailStyle.borderRadius,
              ),
              boxShadow: _ListingDetailStyle.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _ListingDetailStyle.primaryColor.withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: _ListingDetailStyle.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Descripción', style: _ListingDetailStyle.titleStyle),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _listing!.description ?? 'Sin descripción disponible.',
                  style: _ListingDetailStyle.bodyStyle,
                ),
              ],
            ),
          ),

          const SizedBox(height: _ListingDetailStyle.sectionSpacing),

          // Sección Iniciar Trueque
          _buildTradeSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSellerCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SellerProfileScreen(
              sellerId: _listing!.ownerUserId,
              sellerName: _listing!.ownerName ?? "Anónimo",
              sellerAvatarUrl: _listing!.ownerAvatarUrl,
              sellerRating: _listing!.ownerRating,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(_ListingDetailStyle.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _ListingDetailStyle.cardColor,
          borderRadius: BorderRadius.circular(_ListingDetailStyle.borderRadius),
          boxShadow: _ListingDetailStyle.softShadow,
          border: Border.all(color: _ListingDetailStyle.borderColor),
        ),
        child: Row(
          children: [
            // Avatar
            Hero(
              tag: 'seller_${_listing!.ownerUserId}',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _ListingDetailStyle.primaryColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: _listing!.ownerAvatarUrl != null
                    ? NetworkImage(
                      _listing!.ownerAvatarUrl!.startsWith('http')
                        ? _listing!.ownerAvatarUrl!
                        : '${AppConstants.apiBaseUrl}${_listing!.ownerAvatarUrl}',
                    )
    : null,
                  backgroundColor: _ListingDetailStyle.primaryColor.withOpacity(
                    0.1,
                  ),
                  child: _listing!.ownerAvatarUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          color: _ListingDetailStyle.primaryColor,
                          size: 28,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vendido por', style: _ListingDetailStyle.labelStyle),
                  const SizedBox(height: 4),
                  Text(
                    _listing!.ownerName ?? 'Anónimo',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _ListingDetailStyle.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Rating y flecha
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _listing!.ownerRating > 0
                            ? _listing!.ownerRating.toStringAsFixed(1)
                            : '-',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver perfil',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _ListingDetailStyle.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: _ListingDetailStyle.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ListingDetailStyle.cardColor,
        borderRadius: BorderRadius.circular(_ListingDetailStyle.borderRadius),
        boxShadow: _ListingDetailStyle.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _ListingDetailStyle.primaryColor,
                      _ListingDetailStyle.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Iniciar Trueque',
                    style: _ListingDetailStyle.titleStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '¿Te interesa este producto?',
                    style: _ListingDetailStyle.labelStyle,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Input de mensaje
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                _ListingDetailStyle.smallBorderRadius,
              ),
              color: _ListingDetailStyle.backgroundColor,
              border: Border.all(color: _ListingDetailStyle.borderColor),
            ),
            child: TextField(
              controller: _messageController,
              onTap: () {
                if (_messageController.text.trim().isEmpty &&
                    _listing != null) {
                  final defaultMsg =
                      "Hola, estoy interesado en tu '${_listing!.title}'";
                  _messageController.text = defaultMsg;
                  _messageController.selection = TextSelection.fromPosition(
                    TextPosition(offset: defaultMsg.length),
                  );
                }
              },
              style: GoogleFonts.inter(
                fontSize: 15,
                color: _ListingDetailStyle.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Mensaje inicial (Opcional)',
                labelStyle: _ListingDetailStyle.labelStyle,
                hintText:
                    "Hola, estoy interesado en tu '${_listing!.title}'...",
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _ListingDetailStyle.smallBorderRadius,
                  ),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 20),

          // Botón principal
          _isCreatingTrade
              ? Center(
                  child: CircularProgressIndicator(
                    color: _ListingDetailStyle.primaryColor,
                    strokeWidth: 3,
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TradeCreateScreen(
                          targetListingId: _listingId!,
                          targetTitle: _listing!.title,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _ListingDetailStyle.primaryColor,
                          _ListingDetailStyle.primaryColor.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        _ListingDetailStyle.smallBorderRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _ListingDetailStyle.primaryColor.withOpacity(
                            0.3,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.handshake_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Crear Oferta',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
