import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/trade_provider.dart';
import '../../dto/listing/listing_dto.dart';
import '../../dto/trade/trade_create_dto.dart';
import '../../core/app_export.dart'; // Para AppColors y AppRoutes

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
              backgroundColor: AppColors.errorColor),
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
            backgroundColor: AppColors.warningColor),
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
              backgroundColor: AppColors.successColor),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al enviar oferta: ${e.toString()}'),
              backgroundColor: AppColors.errorColor),
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
                child: const Icon(Icons.error_outline)),
          ),
          const SizedBox(height: 16),
          // Título
          Text(_listing!.title,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          // Precio
          Text('${_listing!.trueCoinValue} TrueCoins',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Dueño
          Text('Publicado por: ${_listing!.ownerName ?? "Anónimo"}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          // Descripción
          Text(_listing!.description ?? 'Sin descripción.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // --- Formulario para Iniciar Trueque ---
          Text('Iniciar Trueque',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            onTap: () {
              // Prefill default message including the listing title when user
              // taps the field and it is currently empty so they can edit it.
              if (_messageController.text.trim().isEmpty && _listing != null) {
                final defaultMsg = "Hola, estoy interesado en tu '${_listing!.title}'";
                _messageController.text = defaultMsg;
                _messageController.selection = TextSelection.fromPosition(
                    TextPosition(offset: defaultMsg.length));
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
                  onPressed: _handleCreateTrade,
                  child: const Text('Enviar Oferta'),
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, 50), // Botón ancho
                  ),
                )
        ],
      ),
    );
  }
}