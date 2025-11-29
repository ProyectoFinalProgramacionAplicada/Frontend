// lib/dto/trade/trade_update_dto.dart
class TradeUpdateDto {
  final int? offeredListingId;
  final int? targetListingId;
  final String? message;
  final int? requestedOtherListingId;
  final double? offeredTrueCoins;
  final double? requestedTrueCoins;

  TradeUpdateDto({
    this.offeredListingId,
    this.targetListingId,
    this.message,
    this.requestedOtherListingId,
    this.offeredTrueCoins,
    this.requestedTrueCoins,
  });

  factory TradeUpdateDto.fromJson(Map<String, dynamic> json) {
    return TradeUpdateDto(
      offeredListingId: json['offeredListingId'],
      targetListingId: json['targetListingId'],
      message: json['message'],
      requestedOtherListingId: json['requestedOtherListingId'],
      offeredTrueCoins: json['offeredTrueCoins'] != null
          ? (json['offeredTrueCoins'] as num).toDouble()
          : null,
      requestedTrueCoins: json['requestedTrueCoins'] != null
          ? (json['requestedTrueCoins'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'offeredListingId': offeredListingId,
    'targetListingId': targetListingId,
    'message': message,
    'requestedOtherListingId': requestedOtherListingId,
    'offeredTrueCoins': offeredTrueCoins,
    'requestedTrueCoins': requestedTrueCoins,
  };
}
