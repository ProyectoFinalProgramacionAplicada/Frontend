// lib/dto/wallet/wallet_adjust_request.dart
class WalletAdjustRequest {
  final int userId;
  final double amount;
  final String? reason;

  const WalletAdjustRequest({
    required this.userId,
    required this.amount,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'amount': amount,
    if (reason != null) 'reason': reason,
  };
}
