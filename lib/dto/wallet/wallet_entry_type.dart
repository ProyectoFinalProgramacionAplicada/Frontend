// lib/dto/wallet/wallet_entry_type.dart
enum WalletEntryType {
  Deposit, // 0
  Withdrawal, // 1
  TradeSent, // 2
  TradeReceived, // 3
  P2PDeposit, // 4
  P2PWithdrawal, // 5
  Adjustment, // 6 (reservado para movimientos administrativos/P2P extra)
}
