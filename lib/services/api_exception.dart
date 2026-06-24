/// Single exception type for every API call in the app.
///
/// [statusCode] is null when the request never got a response (network or
/// decoding failure). A 401 means the session is no longer valid; the
/// AuthController turns that into a logout in one place.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
