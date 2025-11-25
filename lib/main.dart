import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/listing_provider.dart';
import 'providers/trade_provider.dart';
import 'providers/review_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/market_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/p2p_order_provider.dart';
import 'services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crear AuthProvider e intentar restaurar sesión antes de iniciar la app
  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();

  runApp(TruekApp(initialAuthProvider: authProvider));
}

class TruekApp extends StatelessWidget {
  final AuthProvider initialAuthProvider;
  const TruekApp({super.key, required this.initialAuthProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: initialAuthProvider),
        ChangeNotifierProvider(create: (_) => ListingProvider()),
        ChangeNotifierProvider(create: (_) => TradeProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => MarketProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => P2POrderProvider(ApiClient().dio)),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TruekApp',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            initialRoute: initialAuthProvider.isLoggedIn
                ? AppRoutes.home
                : AppRoutes.login,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
