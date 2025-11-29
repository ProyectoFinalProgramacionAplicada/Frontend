import 'package:provider/provider.dart';
import 'package:truekapp/screens/profile/seller_profile_screen.dart';
import '../../providers/listing_provider.dart';
import '../../providers/trade_provider.dart';
import '../../dto/listing/listing_dto.dart';
import '../../dto/trade/trade_create_dto.dart';
import '../../core/app_export.dart'; // Para AppColors y AppRoutes
import '../../screens/trade/trade_create_screen.dart';

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
      appBar: AppBar(
        title: Text(_isLoading ? 'Cargando...' : _listing?.title ?? 'Detalle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listing == null
          ? const Center(child: Text('No se pudo cargar la publicación.'))
          : _buildListingDetails(),
    );
  }

  Widget _buildListingDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          Image.network(
            _listing!.imageUrl,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Container(height: 250, color: Colors.grey[300]),
            errorBuilder: (context, error, stackTrace) => Container(
              height: 250,
              color: Colors.grey[300],
              child: const Icon(Icons.error_outline),
            ),
          ),
          const SizedBox(height: 16),
          // Título
          Text(
            _listing!.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          // Precio
          Text(
            '${_listing!.trueCoinValue} TrueCoins',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Dueño
          // --- TARJETA DE VENDEDOR (Inicio) ---
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              // Navegar al nuevo perfil del vendedor
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Hero(
                    tag:
                        'seller_${_listing!.ownerUserId}', // Debe coincidir con el tag en SellerProfile
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: _listing!.ownerAvatarUrl != null
                          ? NetworkImage(
                              '${AppConstants.apiBaseUrl}${_listing!.ownerAvatarUrl}',
                            )
                          : null,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: _listing!.ownerAvatarUrl == null
                          ? Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info Nombre + Rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Vendido por:",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _listing!.ownerName ?? "Anónimo",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Estrellas a la derecha
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            _listing!.ownerRating > 0
                                ? _listing!.ownerRating.toStringAsFixed(1)
                                : "-",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        "Ver perfil >",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // --- TARJETA DE VENDEDOR (Fin) ---
          const SizedBox(height: 16),
          // Descripción
          Text(
            _listing!.description ?? 'Sin descripción.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // --- Formulario para Iniciar Trueque ---
          Text(
            'Iniciar Trueque',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            onTap: () {
              // Prefill default message including the listing title when user
              // taps the field and it is currently empty so they can edit it.
              if (_messageController.text.trim().isEmpty && _listing != null) {
                final defaultMsg =
                    "Hola, estoy interesado en tu '${_listing!.title}'";
                _messageController.text = defaultMsg;
                _messageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: defaultMsg.length),
                );
              }
            },
            decoration: InputDecoration(
              labelText: 'Mensaje inicial (Opcional)',
              hintText: "Hola, estoy interesado en tu '${_listing!.title}'...",
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _isCreatingTrade
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: () {
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
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Crear Oferta'),
                ),
        ],
      ),
    );
  }
}
