/// Single exception type for every API call in the app.
///
/// [statusCode] is null when the request never got a response (network or
/// decoding failure). A 401 means the session is no longer valid; the
/// AuthController turns that into a logout in one place.
///
/// [fieldErrors] holds the per-field validation messages from a 422 response
/// (the API's `data.errors`), already flattened into a single list. It is empty
/// for any other error, so callers can show the list when present.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const [],
  });

  final String message;
  final int? statusCode;
  final List<String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;

  /// Field errors of [exception] when it is an [ApiException], empty otherwise.
  /// Lets callers pass any caught error without checking the type themselves.
  static List<String> fieldErrorsOf(Object exception) {
    return exception is ApiException ? exception.fieldErrors : const [];
  }

  @override
  String toString() => message;
}
