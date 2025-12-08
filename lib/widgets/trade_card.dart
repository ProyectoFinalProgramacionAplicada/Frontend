import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dto/trade/trade_dto.dart';
import '../dto/trade/trade_status.dart';
import '../providers/trade_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/listing_provider.dart';
import '../dto/trade/trade_update_status_dto.dart';
import '../dto/listing/listing_dto.dart';
import '../services/listing_service.dart';
import '../widgets/trade_counter_offer_dialog.dart';
import '../screens/trade/trade_chat_screen.dart';

class TradeCard extends StatelessWidget {
  final TradeDto trade;
  const TradeCard({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final tradeProvider = Provider.of<TradeProvider>(context, listen: false);
    final listingProvider = Provider.of<ListingProvider>(
      context,
      listen: false,
    );

    final currentUser = auth.currentUser;
    final currentUserId = currentUser?.id;
    final isSeller =
        currentUserId != null && currentUserId == trade.listingOwnerId;
    final isInitiator =
        currentUserId != null && currentUserId == trade.initiatorUserId;
    final isParticipant =
        currentUserId != null &&
        (currentUserId == trade.listingOwnerId ||
            currentUserId == trade.initiatorUserId);
    final isPending = trade.status == TradeStatus.Pending;
    final isLastOfferFromOther =
        isParticipant &&
        trade.lastOfferByUserId != null &&
        trade.lastOfferByUserId != currentUserId;
    final canAccept = isParticipant && isPending && isLastOfferFromOther;
    final canCounterOffer = isParticipant && isPending;
    final canReject = isSeller && isPending;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Si es oferta recibida (no soy iniciador pero soy vendedor), mostrar quién la hizo
            if (isSeller && !isInitiator)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Oferta de ${trade.initiatorUserId}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                // Thumbnail del listing objetivo
                FutureBuilder<ListingDto>(
                  future: ListingService().getListingById(
                    trade.targetListingId,
                  ),
                  builder: (context, snap) {
                    final img = snap.hasData ? snap.data!.imageUrl : null;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: img != null
                          ? Image.network(
                              img,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image),
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image),
                            ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<String?>(
                    future: tradeProvider.fetchListingTitle(
                      trade.targetListingId,
                    ),
                    builder: (context, snap) {
                      final title =
                          snap.data ?? 'Publicación #${trade.targetListingId}';
                      return Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  trade.status.toString().split('.').last,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (trade.offeredListingId != null) ...[
                    FutureBuilder<ListingDto>(
                      future: ListingService().getListingById(
                        trade.offeredListingId!,
                      ),
                      builder: (context, snap) {
                        if (snap.hasData) {
                          final l = snap.data!;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  l.imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(label: Text(l.title)),
                            ],
                          );
                        }
                        return Chip(
                          label: Text(
                            'Listing ofrecido: ${trade.offeredListingId}',
                          ),
                        );
                      },
                    ),
                  ],
                  if (trade.offeredTrueCoins != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Chip(
                        label: Text('Ofrece ${trade.offeredTrueCoins} TC'),
                      ),
                    ),
                  if (trade.requestedTrueCoins != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Chip(
                        label: Text('Solicita ${trade.requestedTrueCoins} TC'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TradeChatScreen(),
                          settings: RouteSettings(arguments: trade.id),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Contraoferta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: canCounterOffer
                        ? () async {
                            final me = currentUser!;
                            final rawMyListings = await listingProvider
                                .getListingsByOwner(me.id);
                            final Map<int, ListingDto> byMyId = {};
                            for (final l in rawMyListings) {
                              byMyId[l.id] = l;
                            }
                            final myListings = byMyId.values.toList();

                            final result = await showDialog<dynamic>(
                              context: context,
                              builder: (_) => TradeCounterOfferDialog(
                                myListings: myListings,
                                currentOfferedListingId: trade.offeredListingId,
                                currentOfferedTrueCoins: trade.offeredTrueCoins,
                                currentRequestedTrueCoins:
                                    trade.requestedTrueCoins,
                              ),
                            );

                            if (result is Map) {
                              try {
                                await tradeProvider.sendCounterOffer(
                                  trade.id,
                                  offeredListingId:
                                      result['offeredListingId'] as int?,
                                  offeredTrueCoins:
                                      result['offeredTrueCoins'] as double?,
                                  requestedTrueCoins:
                                      result['requestedTrueCoins'] as double?,
                                  targetListingId: trade.targetListingId,
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Contraoferta enviada'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          }
                        : null,
                  ),
                  const SizedBox(width: 8),
                  if (canAccept) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Aceptar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        try {
                          await tradeProvider.acceptTrade(trade.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Oferta aceptada'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final message = e.toString().replaceFirst(
                              'Exception: ',
                              '',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (canReject) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        try {
                          await tradeProvider.updateTradeStatus(
                            trade.id,
                            TradeUpdateStatusDto(status: TradeStatus.Cancelled),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Oferta rechazada'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
