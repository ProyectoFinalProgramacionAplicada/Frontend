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

  // Campos nuevos para lógica de roles
  final int listingOwnerId;
  final int initiatorUserId;

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
  });

  factory TradeDto.fromJson(Map<String, dynamic> json) {
    return TradeDto(
      id: json['id'],
      requesterUserId: json['requesterUserId'],
      ownerUserId: json['ownerUserId'],
      targetListingId: json['targetListingId'],
      offeredListingId: json['offeredListingId'],
      // Manejo robusto del enum
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
      // Mapeo de los nuevos campos
      listingOwnerId: json['listingOwnerId'] ?? json['ownerUserId'] ?? 0,
      initiatorUserId: json['initiatorUserId'] ?? json['requesterUserId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'requesterUserId': requesterUserId,
    'ownerUserId': ownerUserId,
    'targetListingId': targetListingId,
    'offeredListingId': offeredListingId,
    'status': status.index,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'offeredTrueCoins': offeredTrueCoins,
    'requestedTrueCoins': requestedTrueCoins,
    'listingOwnerId': listingOwnerId,
    'initiatorUserId': initiatorUserId,
  };
}
