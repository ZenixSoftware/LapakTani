import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/navigation/role_based_app_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/splash_screen.dart';

import 'features/orders/screens/buyer_orders_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}
  runApp(const LapakTaniApp());
}

class LapakTaniApp extends StatefulWidget {
  const LapakTaniApp({super.key});

  @override
  State<LapakTaniApp> createState() => _LapakTaniAppState();
}

class _LapakTaniAppState extends State<LapakTaniApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'LapakTani',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleBasedAppShell(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const RoleBasedAppShell(),
        '/dashboard': (context) => const RoleBasedAppShell(),
        '/orders': (context) => const BuyerOrdersScreen(),
      },
    );
  }
}
