import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/trade/trade_chat_screen.dart';
import 'screens/trade/trade_list_screen.dart';
import 'screens/trade/trade_detail_screen.dart';
import 'screens/trade/trade_create_screen.dart';
import 'screens/debug/token_debug_screen.dart';
import 'screens/listing/listing_detail_screen.dart' hide MainScreen;
import 'screens/wallet/wallet_screen.dart';
// Importamos la nueva pantalla de perfil
import 'screens/profile/profile_screen.dart';
// Admin
import 'screens/admin/active_users_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String listingDetail = '/listing-detail';
  static const String trade = '/trade';
  static const String tradeList = '/trades';
  static const String tradeChat = '/trade-chat';
  static const String tradeDetail = '/trade-detail';
  static const String review = '/review';
  static const String wallet = '/wallet';
  static const String settings = '/settings';
  // Nueva ruta constante
  static const String profile = '/profile';
  static const String adminActiveUsers = '/admin/active-users';
  static const String adminUserDetail = '/admin/user-detail';

  static Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginScreen(),
    home: (_) => const MainScreen(),
    register: (_) => const RegisterScreen(),
    trade: (_) => const TradeCreateScreen(),
    tradeChat: (_) => const TradeChatScreen(),
    tradeList: (_) => const TradeListScreen(),
    tradeDetail: (_) => const TradeDetailScreen(),
    '/debug-token': (_) => const TokenDebugScreen(),
    listingDetail: (_) => const ListingDetailScreen(),
    wallet: (_) => const WalletScreen(),

    // Registramos la pantalla de perfil aquí
    profile: (_) => const ProfileScreen(),
    adminActiveUsers: (_) => const ActiveUsersScreen(),
    adminUserDetail: (_) => const Scaffold(
      body: SizedBox(),
    ), // placeholder, screen will be registered after creation
  };
}
