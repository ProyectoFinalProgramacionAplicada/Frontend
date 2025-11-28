class P2POrderType {
  static const int deposit = 0;
  static const int withdraw = 1;
}

class P2POrderCreateRequest {
  final int type;              // 0 = Deposit, 1 = Withdraw
  final double amountBob;
  final double amountTrueCoins;
  final double rate;
  final String? paymentMethod;

  P2POrderCreateRequest({
    required this.type,
    required this.amountBob,
    required this.amountTrueCoins,
    required this.rate,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'amountBob': amountBob,
        'amountTrueCoins': amountTrueCoins,
        'rate': rate,
        'paymentMethod': paymentMethod,
      };
}
