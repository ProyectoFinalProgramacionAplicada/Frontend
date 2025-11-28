import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trade_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../dto/listing/listing_dto.dart';
import '../../widgets/trade_counter_offer_dialog.dart';
import '../../dto/trade/trade_dto.dart';
import '../../dto/trade/trade_status.dart';
import '../../dto/trade/trade_update_status_dto.dart';
import 'trade_chat_screen.dart';

class TradeDetailScreen extends StatefulWidget {
  const TradeDetailScreen({Key? key}) : super(key: key);

  @override
  State<TradeDetailScreen> createState() => _TradeDetailScreenState();
}

class _TradeDetailScreenState extends State<TradeDetailScreen> {
  TradeDto? _trade;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      final provider = Provider.of<TradeProvider>(context, listen: false);
      final found = provider.myTrades.where((t) => t.id == args).toList();
      if (found.isNotEmpty) {
        _trade = found.first;
      } else {
        // if not found, refresh and try again
        provider.fetchMyTrades().then((_) {
          final again = provider.myTrades.where((t) => t.id == args).toList();
          if (mounted)
            setState(() => _trade = again.isNotEmpty ? again.first : null);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tradeProvider = Provider.of<TradeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (_trade == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSeller = auth.currentUser?.id == _trade!.listingOwnerId;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Trueque')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trueque #${_trade!.id}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String?>(
              future: tradeProvider.fetchListingTitle(_trade!.targetListingId),
              builder: (context, snap) =>
                  Text(snap.data ?? 'Publicación #${_trade!.targetListingId}'),
            ),
            const SizedBox(height: 8),
            if (_trade!.offeredListingId != null)
              Text('Ofreció listing ID: ${_trade!.offeredListingId}'),
            if (_trade!.offeredTrueCoins != null)
              Text('Ofreció: ${_trade!.offeredTrueCoins} TC'),
            if (_trade!.requestedTrueCoins != null)
              Text('Solicitó: ${_trade!.requestedTrueCoins} TC'),
            const Spacer(),

            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text('Abrir Chat'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TradeChatScreen(),
                      settings: RouteSettings(arguments: _trade!.id),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Contraoferta'),
                  onPressed: () async {
                    final listingProvider = Provider.of<ListingProvider>(
                      context,
                      listen: false,
                    );
                    final me = auth.currentUser!;
                    final rawMyListings = await listingProvider
                        .getListingsByOwner(me.id);
                    final Map<int, ListingDto> byMyId = {};
                    for (final l in rawMyListings)
                      if (l.id != null) byMyId[l.id] = l;
                    final myListings = byMyId.values.toList();

                    final opponentId = (me.id == _trade!.initiatorUserId)
                        ? _trade!.listingOwnerId
                        : _trade!.initiatorUserId;
                    final rawOppListings = await listingProvider
                        .getListingsByOwner(opponentId);
                    final Map<int, ListingDto> byOppId = {};
                    for (final l in rawOppListings)
                      if (l.id != null) byOppId[l.id] = l;
                    final opponentListings = byOppId.values.toList();

                    final res = await showDialog(
                      context: context,
                      builder: (_) => TradeCounterOfferDialog(
                        myListings: myListings,
                        opponentListings: opponentListings,
                        currentOfferedListingId: _trade!.offeredListingId,
                        currentOfferedTrueCoins: _trade!.offeredTrueCoins,
                        currentRequestedTrueCoins: _trade!.requestedTrueCoins,
                      ),
                    );
                    if (res is Map) {
                      try {
                        final requestedOtherListingId =
                            res['requestedOtherListingId'] as int?;
                        String? message;
                        if (requestedOtherListingId != null) {
                          final title = opponentListings
                              .firstWhere(
                                (l) => l.id == requestedOtherListingId,
                                orElse: () => ListingDto(
                                  id: requestedOtherListingId,
                                  title:
                                      'publicación #$requestedOtherListingId',
                                  trueCoinValue: 0.0,
                                  isPublished: true,
                                  imageUrl: '',
                                  latitude: 0.0,
                                  longitude: 0.0,
                                  ownerUserId: opponentId,
                                  ownerName: null,
                                  ownerAvatarUrl: null,
                                  ownerRating: 0.0,
                                ),
                              )
                              .title;
                          message =
                              'Por favor, cambia tu publicación a: $title (id: $requestedOtherListingId)';
                        }

                        await tradeProvider.sendCounterOffer(
                          _trade!.id,
                          offeredListingId: res['offeredListingId'] as int?,
                          offeredTrueCoins: res['offeredTrueCoins'] as double?,
                          requestedTrueCoins:
                              res['requestedTrueCoins'] as double?,
                          message: message,
                        );
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contraoferta enviada'),
                            ),
                          );
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
                if (isSeller && _trade!.status == TradeStatus.Pending) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Aceptar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      try {
                        await tradeProvider.acceptTrade(_trade!.id);
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Oferta aceptada'),
                              backgroundColor: Colors.green,
                            ),
                          );
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      try {
                        await tradeProvider.updateTradeStatus(
                          _trade!.id,
                          TradeUpdateStatusDto(status: TradeStatus.Cancelled),
                        );
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Oferta rechazada'),
                              backgroundColor: Colors.red,
                            ),
                          );
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
