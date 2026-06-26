import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static const String _dartDefineBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _fallbackLocalBaseUrl = 'http://192.168.15.4:8000/api';
  static const String _fallbackProductionBaseUrl =
      'https://api.rodapresa.com.br/api';

  static String get baseUrl {
    final dartDefineBaseUrl = _dartDefineBaseUrl.trim();

    if (dartDefineBaseUrl.isNotEmpty) {
      return dartDefineBaseUrl;
    }

    final configuredBaseUrl = kReleaseMode
        ? _env('API_PRODUCTION_BASE_URL')
        : _env('API_LOCAL_BASE_URL');

    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    return kReleaseMode ? _fallbackProductionBaseUrl : _fallbackLocalBaseUrl;
  }

  static String _env(String key) => dotenv.env[key]?.trim() ?? '';
}
