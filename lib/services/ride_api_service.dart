import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/city.dart';
import '../models/ride.dart';

class RideApiService {
  RideApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<List<Ride>> fetchRides({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final uri = _uri('/rides', {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius_km': radiusKm.round().toString(),
    });

    final response = await _get(uri);

    return _parseRides(response.body);
  }

  Future<Ride> fetchRide(int id) async {
    final response = await _get(_uri('/rides/$id'));

    return _parseRide(response.body);
  }

  Future<List<City>> searchCities({
    required String search,
    int limit = 20,
  }) async {
    final uri = _uri('/cities', {'search': search, 'limit': limit.toString()});
    final response = await _get(uri);

    return _parseCities(response.body);
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      final response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw RideApiException('A API respondeu com ${response.statusCode}.');
      }

      return response;
    } on RideApiException {
      rethrow;
    } catch (_) {
      throw const RideApiException('Não foi possível conectar à API.');
    }
  }

  void close() => _client.close();

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final cleanBaseUrl = _baseUrl.replaceFirst(RegExp(r'/+$'), '');

    return Uri.parse(
      '$cleanBaseUrl$path',
    ).replace(queryParameters: queryParameters);
  }

  List<Ride> _parseRides(String body) {
    final decoded = _decode(body);
    final data = decoded['data'];

    if (data is! List) {
      throw const RideApiException('Resposta inválida da API.');
    }

    return [
      for (final item in data)
        Ride.fromJson(_asJsonObject(item, 'Item de role inválido.')),
    ];
  }

  List<City> _parseCities(String body) {
    final decoded = _decode(body);
    final data = decoded['data'];

    if (data is! List) {
      throw const RideApiException('Resposta inválida da API.');
    }

    try {
      return [
        for (final item in data)
          City.fromJson(_asJsonObject(item, 'Item de cidade inválido.')),
      ];
    } catch (_) {
      throw const RideApiException('Resposta inválida da API.');
    }
  }

  Ride _parseRide(String body) {
    final decoded = _decode(body);

    return Ride.fromJson(_asJsonObject(decoded['data'], 'Role inválido.'));
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);

      return _asJsonObject(decoded, 'Resposta inválida da API.');
    } catch (_) {
      throw const RideApiException('Resposta inválida da API.');
    }
  }

  Map<String, dynamic> _asJsonObject(dynamic value, String message) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    throw RideApiException(message);
  }
}

class RideApiException implements Exception {
  const RideApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
