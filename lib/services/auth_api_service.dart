import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../models/json_parsers.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AuthApiService {
  AuthApiService({http.Client? client, String? baseUrl})
    : _apiClient = ApiClient(client: client, baseUrl: baseUrl);

  final ApiClient _apiClient;

  Future<AuthSession> loginWithGoogleToken(String idToken) async {
    final response = await _apiClient.post(_apiClient.uri('/auth/google'), {
      'id_token': idToken,
    });

    try {
      return AuthSession.fromJson(_apiClient.decode(response.body));
    } catch (_) {
      throw const ApiException('Resposta de login inválida.');
    }
  }

  Future<AppUser> fetchMe(String sanctumToken) async {
    final response = await _apiClient.get(
      _apiClient.uri('/auth/me'),
      authToken: sanctumToken,
    );

    return _parseUser(response);
  }

  Future<AppUser> updateProfile({
    required String sanctumToken,
    bool updateMotorcycle = false,
    String? motorcycle,
    int? cityId,
  }) async {
    final payload = <String, dynamic>{};

    if (updateMotorcycle) {
      payload['motorcycle'] = motorcycle;
    }

    if (cityId != null) {
      payload['city_id'] = cityId;
    }

    final response = await _apiClient.patch(
      _apiClient.uri('/auth/me'),
      payload,
      authToken: sanctumToken,
    );

    return _parseUser(response);
  }

  AppUser _parseUser(http.Response response) {
    try {
      return AppUser.fromJson(
        asJsonObject(_apiClient.decode(response.body)['data']),
      );
    } catch (_) {
      throw const ApiException('Resposta de usuário inválida.');
    }
  }

  Future<void> logout(String sanctumToken) async {
    await _apiClient.post(
      _apiClient.uri('/auth/logout'),
      const <String, dynamic>{},
      authToken: sanctumToken,
      expectedStatusCodes: const [204],
    );
  }

  void close() => _apiClient.close();
}
