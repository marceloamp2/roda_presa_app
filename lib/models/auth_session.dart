import 'app_user.dart';
import 'json_parsers.dart';

class AuthSession {
  const AuthSession({required this.user, required this.token});

  final AppUser user;
  final String token;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final data = asJsonObject(json['data']);
    final token = data['token'];

    if (token is! String || token.trim().isEmpty) {
      throw const FormatException('Resposta de login inválida.');
    }

    return AuthSession(
      user: AppUser.fromJson(data),
      token: token,
    );
  }
}
