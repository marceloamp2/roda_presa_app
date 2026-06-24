import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_exception.dart';
import '../services/auth_api_service.dart';
import '../services/auth_storage.dart';
import '../services/google_identity_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    AuthApiService? authApiService,
    GoogleIdentityService? googleIdentityService,
    AuthStorage? authStorage,
  }) : _authApiService = authApiService ?? AuthApiService(),
       _googleIdentityService =
           googleIdentityService ?? GoogleIdentityService(),
       _authStorage = authStorage ?? const AuthStorage();

  final AuthApiService _authApiService;
  final GoogleIdentityService _googleIdentityService;
  final AuthStorage _authStorage;

  AppUser? _user;
  String? _token;
  bool _isRestoring = false;
  bool _isSigningIn = false;

  AppUser? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isRestoring => _isRestoring;
  bool get isSigningIn => _isSigningIn;

  Future<void> restoreSession() async {
    _isRestoring = true;
    notifyListeners();

    try {
      final storedToken = await _authStorage.readToken();

      if (storedToken == null || storedToken.isEmpty) {
        return;
      }

      final fetchedUser = await _authApiService.fetchMe(storedToken);
      _token = storedToken;
      _user = fetchedUser;
    } on ApiException catch (exception) {
      if (exception.isUnauthorized) {
        await _clearSession();
      }
    } catch (_) {
      // Restore failures must not block the public feed.
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    if (_isSigningIn) {
      return;
    }

    _isSigningIn = true;
    notifyListeners();

    try {
      final idToken = await _googleIdentityService.requestIdToken();
      final session = await _authApiService.loginWithGoogleToken(idToken);

      await _authStorage.saveToken(session.token);
      _token = session.token;
      _user = session.user;
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final currentToken = _token;

    if (currentToken != null && currentToken.isNotEmpty) {
      try {
        await _authApiService.logout(currentToken);
      } catch (_) {
        // Local logout must happen even if the API call fails.
      }
    }

    try {
      await _googleIdentityService.signOut();
    } catch (_) {
      // Local logout must happen even if Google sign-out fails.
    }

    await _clearSession();
    notifyListeners();
  }

  Future<void> clearInvalidSession() async {
    await _clearSession();
    notifyListeners();
  }

  /// Clears the session when [exception] means the token is no longer valid.
  ///
  /// Returns true when the session was expired (so the caller can send the
  /// user back to the public feed), keeping the "401 means logged out" rule
  /// in one place instead of in every screen.
  Future<bool> handleApiException(Object exception) async {
    if (exception is ApiException && exception.isUnauthorized) {
      await clearInvalidSession();
      return true;
    }

    return false;
  }

  Future<void> _clearSession() async {
    _token = null;
    _user = null;
    await _authStorage.clearToken();
  }

  @override
  void dispose() {
    _authApiService.close();
    super.dispose();
  }
}
