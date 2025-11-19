class MarketRateDto {
  final double price;

  MarketRateDto({required this.price});

  factory MarketRateDto.fromJson(Map<String, dynamic> json) {
    return MarketRateDto(price: (json['price'] as num).toDouble());
  }
}
