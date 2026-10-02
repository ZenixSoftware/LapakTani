import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/onboarding/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    // ignore: deprecated_member_use
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const LapakTaniApp());
}

class LapakTaniApp extends StatelessWidget {
  const LapakTaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LapakTani',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}
