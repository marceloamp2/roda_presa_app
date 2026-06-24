import 'app_user.dart';
import 'json_parsers.dart';

class AuthSession {
  const AuthSession({required this.user, required this.token});

  final AppUser user;
  final String token;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final userData = json['data'];

    if (token is! String || token.trim().isEmpty) {
      throw const FormatException('Resposta de login inválida.');
    }

    return AuthSession(
      user: AppUser.fromJson(asJsonObject(userData)),
      token: token,
    );
  }
}
