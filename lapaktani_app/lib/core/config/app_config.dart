import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String _compileTimeBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _compileTimeApiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  static bool _loadAttempted = false;

  /// Loads `lapaktani_app/.env` asset once at app startup (or lazily before API calls)
  /// so plain `flutter run` without `--dart-define` still sends the gateway API key.
  static Future<void> ensureLoaded() async {
    if (dotenv.isInitialized || _loadAttempted) return;
    _loadAttempted = true;
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Safe fallback in widget tests or when `.env` asset is omitted with --dart-define
    }
  }

  static String get baseUrl {
    if (_compileTimeBaseUrl.trim().isNotEmpty) {
      return _compileTimeBaseUrl.trim();
    }
    if (dotenv.isInitialized) {
      final envUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
      if (envUrl.isNotEmpty) return envUrl;
    }
    return 'https://api-lapaktani.velosixraptor.my.id/api';
  }

  static String get apiKey {
    if (_compileTimeApiKey.trim().isNotEmpty) {
      return _compileTimeApiKey.trim();
    }
    if (dotenv.isInitialized) {
      final envKey = (dotenv.env['API_KEY'] ?? '').trim();
      if (envKey.isNotEmpty) return envKey;
    }
    return '';
  }
}
