import 'trade_status.dart';

class TradeDto {
  final int id;
  final int requesterUserId;
  final int ownerUserId;
  final int targetListingId;
  final int? offeredListingId;
  final TradeStatus status;
  final String? message;
  final DateTime createdAt;
  final double? offeredTrueCoins;
  final double? requestedTrueCoins;
  final int listingOwnerId;
  final int initiatorUserId;
  final int? lastOfferByUserId;
  // --- CAMPOS VISUALES ---
  final String? requesterAvatarUrl;
  final String? ownerAvatarUrl;
  final String? requesterName; // <--- Nuevo
  final String? ownerName;     // <--- Nuevo
  final String? listingTitle;
  final String? listingImageUrl;

  TradeDto({
    required this.id,
    required this.requesterUserId,
    required this.ownerUserId,
    required this.targetListingId,
    this.offeredListingId,
    required this.status,
    this.message,
    required this.createdAt,
    this.offeredTrueCoins,
    this.requestedTrueCoins,
    required this.listingOwnerId,
    required this.initiatorUserId,
    this.lastOfferByUserId,
    this.requesterAvatarUrl,
    this.ownerAvatarUrl,
    this.requesterName, // <--- Agregar
    this.ownerName,     // <--- Agregar
    this.listingTitle,
    this.listingImageUrl,
  });

  factory TradeDto.fromJson(Map<String, dynamic> json) {
    return TradeDto(
      id: json['id'],
      requesterUserId: json['requesterUserId'],
      ownerUserId: json['ownerUserId'],
      targetListingId: json['targetListingId'],
      offeredListingId: json['offeredListingId'],
      status: json['status'] is int
          ? TradeStatus.values[json['status']]
          : TradeStatus.values.firstWhere(
              (e) => e.toString() == 'TradeStatus.${json['status']}',
              orElse: () => TradeStatus.Pending,
            ),
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      offeredTrueCoins: json['offeredTrueCoins'] != null
          ? (json['offeredTrueCoins'] as num).toDouble()
          : null,
      requestedTrueCoins: json['requestedTrueCoins'] != null
          ? (json['requestedTrueCoins'] as num).toDouble()
          : null,
      listingOwnerId: json['listingOwnerId'] ?? json['ownerUserId'] ?? 0,
      initiatorUserId: json['initiatorUserId'] ?? json['requesterUserId'] ?? 0,
      lastOfferByUserId: json['lastOfferByUserId'],
      
      // Mapeo visual
      requesterAvatarUrl: json['requesterAvatarUrl'],
      ownerAvatarUrl: json['ownerAvatarUrl'],
      requesterName: json['requesterName'], // <--- Mapear
      ownerName: json['ownerName'],         // <--- Mapear
      listingTitle: json['listingTitle'],
      listingImageUrl: json['listingImageUrl'],
    );
  }
  
  // (El toJson no es crítico para mostrar, pero puedes actualizarlo si quieres)
}