// lib/routes.dart
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_screen.dart';
import 'screens/auth/register_screen.dart';
//import 'screens/home/home_screen.dart';
import 'screens/listing/listing_detail_screen.dart';
import 'screens/wallet/wallet_screen.dart';
//import 'screens/trade/trade_screen.dart';
//import 'screens/review/review_screen.dart';
//import 'screens/wallet/wallet_screen.dart';
//import 'screens/settings/settings_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String listingDetail = '/listing-detail';
  static const String trade = '/trade';
  static const String review = '/review';
  static const String wallet = '/wallet';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginScreen(),
    home: (_) => const MainScreen(),
    register: (_) => const RegisterScreen(),
    //home: (_) => const HomeScreen(),
    listingDetail: (_) => const ListingDetailScreen(),
    //trade: (_) => const TradeScreen(),
    //review: (_) => const ReviewScreen(),
    wallet: (_) => const WalletScreen(),
    //settings: (_) => const SettingsScreen(),
  };
}
