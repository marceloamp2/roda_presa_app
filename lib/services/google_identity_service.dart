import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/auth_config.dart';
import 'api_exception.dart';

class GoogleIdentityService {
  GoogleIdentityService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static const List<String> _scopes = ['openid', 'email', 'profile'];

  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  Future<String> requestIdToken() async {
    await _initialize();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const GoogleIdentityException(
        'Este dispositivo não suporta o login do Google pelo app.',
      );
    }

    try {
      final account = await _googleSignIn.authenticate(scopeHint: _scopes);
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const GoogleIdentityException(
          'Não foi possível obter o token do Google.',
        );
      }

      return idToken;
    } on GoogleSignInException catch (exception) {
      throw GoogleIdentityException(_messageForGoogleException(exception));
    } catch (exception) {
      if (exception is GoogleIdentityException) {
        rethrow;
      }

      throw const GoogleIdentityException(
        'Não foi possível entrar com Google agora.',
      );
    }
  }

  Future<void> signOut() async {
    await _initialize();
    await _googleSignIn.signOut();
  }

  Future<void> _initialize() {
    return _initialization ??= _googleSignIn
        .initialize(
          clientId: kIsWeb ? AuthConfig.googleWebClientId : null,
          serverClientId: AuthConfig.googleWebClientId,
        )
        .catchError((Object error) {
          _initialization = null;
          throw error;
        });
  }

  String _messageForGoogleException(GoogleSignInException exception) {
    return switch (exception.code) {
      GoogleSignInExceptionCode.canceled => 'Login cancelado.',
      GoogleSignInExceptionCode.interrupted => 'Login interrompido.',
      GoogleSignInExceptionCode.clientConfigurationError =>
        'Configuração do Google inválida.',
      _ => 'Não foi possível entrar com Google agora.',
    };
  }
}

class GoogleIdentityException implements Exception {
  const GoogleIdentityException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Maps a Google sign-in failure to a user-facing message, falling back to the
/// given message when the exception carries none of its own.
String googleSignInErrorMessage(Object exception, {required String fallback}) {
  if (exception is GoogleIdentityException) {
    return exception.message;
  }

  if (exception is ApiException) {
    return exception.message;
  }

  return fallback;
}
