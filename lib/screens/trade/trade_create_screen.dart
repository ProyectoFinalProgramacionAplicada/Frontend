// lib/screens/trade/trade_create_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trade_provider.dart';
import '../../providers/listing_provider.dart';
import '../../dto/trade/trade_create_dto.dart';
import '../../dto/listing/listing_dto.dart';
import '../../widgets/listing_selector_sheet.dart';
import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';

class TradeCreateScreen extends StatefulWidget {
  final int? targetListingId;
  final String? targetTitle;

  const TradeCreateScreen({Key? key, this.targetListingId, this.targetTitle})
    : super(key: key);

  @override
  State<TradeCreateScreen> createState() => _TradeCreateScreenState();
}

class _TradeCreateScreenState extends State<TradeCreateScreen> {
  int? _targetListingId;
  ListingDto? _selectedTargetListing;
  int? _offeredListingId;
  ListingDto? _selectedOfferedListing;
  double? _offeredTrueCoins;
  double? _requestedTrueCoins;
  bool _isSending = false;

  final _coinsController = TextEditingController();
  final _requestedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Si se pasó un targetListingId, usarlo
    if (widget.targetListingId != null) {
      _targetListingId = widget.targetListingId;
    }
  }

  @override
  void dispose() {
    _coinsController.dispose();
    _requestedController.dispose();
    super.dispose();
  }

  // ============================================================
  // ============================================================
  // (Las listings propias se obtienen directamente desde ListingProvider)
  // ============================================================

  // ============================================================
  // ABRIR SELECTOR DE TARGET LISTING
  // ============================================================
  Future<void> _openTargetListingSelector() async {
    final listingProvider = Provider.of<ListingProvider>(
      context,
      listen: false,
    );

    try {
      // Obtener catálogo de listings disponibles
      await listingProvider.fetchCatalog();
      final allListings = listingProvider.listings;

      if (!mounted) return;

      // Mostrar selector
      final selected = await showModalBottomSheet<ListingDto>(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Selecciona un listing para ofertar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: allListings.isEmpty
                    ? const Center(child: Text("No hay listings disponibles"))
                    : ListView.builder(
                        itemCount: allListings.length,
                        itemBuilder: (ctx, idx) {
                          final listing = allListings[idx];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                listing.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                              ),
                            ),
                            title: Text(listing.title),
                            subtitle: Text(
                              "€${listing.trueCoinValue.toStringAsFixed(2)}",
                            ),
                            onTap: () => Navigator.pop(context, listing),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );

      if (selected != null) {
        setState(() {
          _targetListingId = selected.id;
          _selectedTargetListing = selected;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando listings: $e')));
    }
  }

  // ============================================================
  // ABRIR SELECTOR Y CARGAR LISTINGS EN TIEMPO REAL
  // ============================================================
  Future<void> _openListingSelector() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final listingProvider = Provider.of<ListingProvider>(
      context,
      listen: false,
    );

    final userId = auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para seleccionar un listing.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    List<ListingDto> listings = [];
    try {
      listings = await listingProvider.getListingsByOwner(userId);
    } catch (e) {
      // Log / mostrar error y continuar con lista vacía
      debugPrint('Error cargando listings propios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando tus publicaciones: $e')),
      );
    }

    final selected = await showModalBottomSheet<ListingDto>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ListingSelectorSheet(
        myListings: listings,
        onSelected: (l) => Navigator.pop(context, l),
      ),
    );

    if (selected != null) {
      setState(() {
        _offeredListingId = selected.id;
        _selectedOfferedListing = selected;
      });
    }
  }

  // ============================================================
  // ENVIAR OFERTA
  // ============================================================
  Future<void> _handleSend() async {
    // Validación: no permitir oferta completamente vacía
    final offersListing = _offeredListingId != null;
    final offersCoins = _offeredTrueCoins != null && _offeredTrueCoins! > 0;
    if (!offersListing && !offersCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes ofrecer un listing propio o TrueCoins.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    // Evitar ofrecer el mismo listing objetivo
    if (_offeredListingId != null &&
        _offeredListingId == widget.targetListingId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes ofrecer el mismo listing que estás viendo.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final targetId = _targetListingId ?? widget.targetListingId;
      if (targetId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes seleccionar un listing destino'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        setState(() => _isSending = false);
        return;
      }

      final dto = TradeCreateDto(
        targetListingId: targetId,
        offeredListingId: _offeredListingId,
        offeredTrueCoins: _offeredTrueCoins,
        requestedTrueCoins: _requestedTrueCoins,
      );

      await Provider.of<TradeProvider>(context, listen: false).createTrade(dto);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oferta enviada'),
          backgroundColor: AppColors.successColor,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final targetTitle =
        _selectedTargetListing?.title ??
        widget.targetTitle ??
        "Selecciona un listing";

    return Scaffold(
      appBar: AppBar(
        title: _targetListingId == null
            ? const Text("Crear trueque")
            : Text("Ofertar por: $targetTitle"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mostrar selector de TARGET LISTING si no está seleccionado
            if (_targetListingId == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text("Selecciona un listing para ofertar"),
                    subtitle: const Text(
                      "Busca el listing que deseas intercambiar",
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: _openTargetListingSelector,
                  ),
                ),
              ),

            // LISTING DESTINO (si está seleccionado)
            if (_targetListingId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  leading: _selectedTargetListing == null
                      ? const Icon(Icons.store)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _selectedTargetListing!.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            ),
                          ),
                        ),
                  title: const Text("Listing destino"),
                  subtitle: Text(
                    _selectedTargetListing?.title ?? "Cargando...",
                  ),
                ),
              ),

            // Divider
            const Divider(),
            const SizedBox(height: 16),

            // -------------------------------
            // LISTING PROPIO SELECCIONABLE
            // -------------------------------
            ListTile(
              leading: _selectedOfferedListing == null
                  ? const Icon(Icons.swap_horiz)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _selectedOfferedListing!.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
              title: const Text("Listing ofrecido"),
              subtitle: Text(
                _selectedOfferedListing == null
                    ? "Ninguno seleccionado"
                    : _selectedOfferedListing!.title,
              ),
              trailing: ElevatedButton(
                onPressed: _openListingSelector,
                child: const Text("Seleccionar"),
              ),
            ),

            const SizedBox(height: 12),

            // Ofrecer TrueCoins
            TextField(
              controller: _coinsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: "Ofrecer TrueCoins (opcional)",
              ),
              onChanged: (v) =>
                  _offeredTrueCoins = double.tryParse(v.replaceAll(',', '.')),
            ),

            const SizedBox(height: 12),

            // Pedir TrueCoins
            TextField(
              controller: _requestedController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: "Solicitar TrueCoins (opcional)",
              ),
              onChanged: (v) =>
                  _requestedTrueCoins = double.tryParse(v.replaceAll(',', '.')),
            ),

            const Spacer(),

            _isSending
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleSend,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text("Enviar oferta"),
                  ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
