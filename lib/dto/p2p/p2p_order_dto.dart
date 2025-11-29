class P2POrderStatus {
  static const int pending = 0;
  static const int matched = 1;
  static const int paid = 2;
  static const int released = 3;
  static const int cancelled = 4;
  static const int disputed = 5;
}

class P2POrderDto {
  final int id;
  final int type;
  final int status;
  final double amountBob;
  final double amountTrueCoins;
  final double rate;
  final int creatorUserId;
  final int? counterpartyUserId;
  final String? paymentMethod;
  final DateTime createdAt;

  P2POrderDto({
    required this.id,
    required this.type,
    required this.status,
    required this.amountBob,
    required this.amountTrueCoins,
    required this.rate,
    required this.creatorUserId,
    required this.counterpartyUserId,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory P2POrderDto.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return P2POrderDto(
      id: json['id'] as int,
      type: json['type'] as int,
      status: json['status'] as int,
      amountBob: toDouble(json['amountBob']),
      amountTrueCoins: toDouble(json['amountTrueCoins']),
      rate: toDouble(json['rate']),
      creatorUserId: json['creatorUserId'] as int,
      counterpartyUserId: json['counterpartyUserId'] as int?,
      paymentMethod: json['paymentMethod'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
