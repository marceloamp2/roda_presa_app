import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthConfig {
  const AuthConfig._();

  static String get googleWebClientId {
    final value = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';

    if (value.isEmpty) {
      throw const AuthConfigException(
        'GOOGLE_WEB_CLIENT_ID não foi configurado no app.',
      );
    }

    return value;
  }
}

class AuthConfigException implements Exception {
  const AuthConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}
