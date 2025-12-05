class TradeCounterOfferDto {
  final int? targetListingId;
  final int? offeredListingId;
  final double? offeredTrueCoins;
  final double? requestedTrueCoins;
  final String? message;

  TradeCounterOfferDto({
    this.targetListingId,
    this.offeredListingId,
    this.offeredTrueCoins,
    this.requestedTrueCoins,
    this.message,
  });

  Map<String, dynamic> toJson() => {
        'targetListingId': targetListingId,
        'offeredListingId': offeredListingId,
        'offeredTrueCoins': offeredTrueCoins,
        'requestedTrueCoins': requestedTrueCoins,
        'message': message,
      };
}
