// lib/widgets/trade_counter_offer_dialog.dart
import 'package:flutter/material.dart';
import '../dto/listing/listing_dto.dart';

class TradeCounterOfferDialog extends StatefulWidget {
  final List<ListingDto> myListings;
  final int? currentOfferedListingId;
  final double? currentOfferedTrueCoins;
  final double? currentRequestedTrueCoins;

  const TradeCounterOfferDialog({
    super.key,
    required this.myListings,
    this.currentOfferedListingId,
    this.currentOfferedTrueCoins,
    this.currentRequestedTrueCoins,
  });

  @override
  State<TradeCounterOfferDialog> createState() =>
      _TradeCounterOfferDialogState();
}

class _TradeCounterOfferDialogState extends State<TradeCounterOfferDialog> {
  int? _offeredListingId;
  double? _offeredTrueCoins;
  double? _requestedTrueCoins;
  final _offeredController = TextEditingController();
  final _requestedController = TextEditingController();

  late final List<ListingDto> _uniqueListings;

  @override
  void initState() {
    super.initState();

    // Normalizar y deduplicar listings por id
    final Map<int, ListingDto> byId = {};
    for (final l in widget.myListings) {
      byId[l.id] = l;
    }
    _uniqueListings = byId.values.toList();

    _offeredListingId = widget.currentOfferedListingId;
    _offeredTrueCoins = widget.currentOfferedTrueCoins;
    _requestedTrueCoins = widget.currentRequestedTrueCoins;

    _offeredController.text = _offeredTrueCoins?.toString() ?? '';
    _requestedController.text = _requestedTrueCoins?.toString() ?? '';
  }

  @override
  void dispose() {
    _offeredController.dispose();
    _requestedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Asegurarse de que el listing ofrecido actual esté en las opciones
    final availableIds = _uniqueListings.map((l) => l.id).toSet();
    final safeValue = (_offeredListingId != null &&
            availableIds.contains(_offeredListingId))
        ? _offeredListingId
        : null;

    // Parsear para validar (por si el usuario no disparó onChanged)
    final parsedOfferedCoins = _offeredTrueCoins ??
        double.tryParse(_offeredController.text.replaceAll(',', '.'));
    final parsedRequestedCoins = _requestedTrueCoins ??
        double.tryParse(_requestedController.text.replaceAll(',', '.'));

    final bool isValid =
      (safeValue != null) ||
      (parsedOfferedCoins != null && parsedOfferedCoins > 0) ||
      (parsedRequestedCoins != null && parsedRequestedCoins > 0);

    return AlertDialog(
      title: const Text('Enviar Contraoferta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int?>(
            // usamos el valor "seguro" validado
            initialValue: safeValue,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Sin listing (solo TrueCoins)'),
              ),
              ..._uniqueListings.map(
                (l) => DropdownMenuItem<int?>(
                  value: l.id,
                  child: Text(l.title),
                ),
              ),
            ],
            onChanged: (v) => setState(() {
              _offeredListingId = v;
            }),
            decoration: const InputDecoration(labelText: 'Listing ofrecido'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _offeredController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Ofrecer TrueCoins'),
            onChanged: (v) {
              setState(() {
                _offeredTrueCoins =
                    double.tryParse(v.replaceAll(',', '.'));
              });
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _requestedController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Solicitar TrueCoins'),
            onChanged: (v) {
              setState(() {
                _requestedTrueCoins =
                    double.tryParse(v.replaceAll(',', '.'));
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: isValid
              ? () {
                  // 🔹 Usamos SIEMPRE el estado más reciente
                  final offeredCoins = _offeredTrueCoins ??
                      double.tryParse(
                          _offeredController.text.replaceAll(',', '.'));
                  final requestedCoins = _requestedTrueCoins ??
                      double.tryParse(
                          _requestedController.text.replaceAll(',', '.'));

                  Navigator.of(context).pop({
                    'offeredListingId': _offeredListingId,
                    'offeredTrueCoins': offeredCoins,
                    'requestedTrueCoins': requestedCoins,
                  });
                }
              : null,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
