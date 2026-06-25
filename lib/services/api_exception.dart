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

  static List<String> fieldErrorsOf(Object exception) {
    return exception is ApiException ? exception.fieldErrors : const [];
  }

  @override
  String toString() => message;
}
