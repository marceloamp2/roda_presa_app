import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/json_parsers.dart';
import 'api_exception.dart';

/// Shared HTTP transport for the app's API services.
///
/// Holds the base Uri handling, header assembly, status-code checking and
/// JSON decoding so each service only describes its own endpoints. Every
/// failure surfaces as an [ApiException], so callers handle one type.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUri = Uri.parse(
        (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/+$'), ''),
      );

  final http.Client _client;
  final Uri _baseUri;
  late final List<String> _baseSegments = _baseUri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);

  Future<http.Response> get(
    Uri uri, {
    String? authToken,
    List<int> expectedStatusCodes = const [200],
  }) {
    return _send(() {
      return _client.get(uri, headers: _headers(authToken: authToken));
    }, expectedStatusCodes: expectedStatusCodes);
  }

  Future<http.Response> post(
    Uri uri,
    Map<String, dynamic> payload, {
    String? authToken,
    List<int> expectedStatusCodes = const [200, 201],
  }) {
    return _send(() {
      return _client.post(
        uri,
        headers: _headers(authToken: authToken, hasBody: true),
        body: jsonEncode(payload),
      );
    }, expectedStatusCodes: expectedStatusCodes);
  }

  Future<http.Response> patch(
    Uri uri,
    Map<String, dynamic> payload, {
    String? authToken,
    List<int> expectedStatusCodes = const [200],
  }) {
    return _send(() {
      return _client.patch(
        uri,
        headers: _headers(authToken: authToken, hasBody: true),
        body: jsonEncode(payload),
      );
    }, expectedStatusCodes: expectedStatusCodes);
  }

  Future<http.Response> delete(
    Uri uri, {
    String? authToken,
    List<int> expectedStatusCodes = const [200, 204],
  }) {
    return _send(() {
      return _client.delete(uri, headers: _headers(authToken: authToken));
    }, expectedStatusCodes: expectedStatusCodes);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    required List<int> expectedStatusCodes,
  }) async {
    try {
      final response = await request();

      if (!expectedStatusCodes.contains(response.statusCode)) {
        throw ApiException(
          _errorMessage(response),
          statusCode: response.statusCode,
          fieldErrors: _fieldErrors(response),
        );
      }

      return response;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Não foi possível conectar à API.');
    }
  }

  Uri uri(String path, [Map<String, String>? queryParameters]) {
    final segments = path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);

    return uriFromSegments(segments, queryParameters);
  }

  Uri uriFromSegments(
    List<String> segments, [
    Map<String, String>? queryParameters,
  ]) {
    return _baseUri.replace(
      pathSegments: [..._baseSegments, ...segments],
      queryParameters: queryParameters,
    );
  }

  Map<String, dynamic> decode(String body) {
    try {
      return asJsonObject(jsonDecode(body));
    } catch (_) {
      throw const ApiException('Resposta inválida da API.');
    }
  }

  Map<String, String> _headers({String? authToken, bool hasBody = false}) {
    return {
      'Accept': 'application/json',
      if (hasBody) 'Content-Type': 'application/json',
      if (authToken != null && authToken.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };
  }

  String _errorMessage(http.Response response) {
    try {
      final message = decode(response.body)['message'];

      if (message is String && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      // No usable JSON body; fall back to the status code below.
    }

    return 'A API respondeu com ${response.statusCode}.';
  }

  /// Flattens the per-field validation messages from a 422 body.
  ///
  /// The API returns them under `data.errors` as `{ field: [messages] }`; this
  /// drops the field keys and keeps every message in a single list so the UI
  /// can show them as a plain list. Returns an empty list when absent.
  List<String> _fieldErrors(http.Response response) {
    try {
      final data = decode(response.body)['data'];
      final errors = data is Map<String, dynamic> ? data['errors'] : null;

      if (errors is! Map<String, dynamic>) {
        return const [];
      }

      return [
        for (final messages in errors.values)
          if (messages is List)
            for (final message in messages)
              if (message is String && message.isNotEmpty) message,
      ];
    } catch (_) {
      return const [];
    }
  }

  void close() => _client.close();
}
