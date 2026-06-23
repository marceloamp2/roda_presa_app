import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/city.dart';
import '../models/place.dart';
import '../models/ride.dart';

class RideApiService {
  RideApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUri = Uri.parse(
        (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/+$'), ''),
      );

  final http.Client _client;
  final Uri _baseUri;
  late final List<String> _baseSegments = _baseUri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);

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

  Future<List<PlaceSuggestion>> autocompletePlaces({
    required String search,
    required String sessionToken,
    int limit = 5,
  }) async {
    final uri = _uri('/places/autocomplete', {
      'search': search,
      'session_token': sessionToken,
      'limit': limit.toString(),
    });
    final response = await _get(uri);

    return _parsePlaceSuggestions(response.body);
  }

  Future<SelectedPlace> fetchPlaceDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    final uri = _uriFromSegments(
      ['places', placeId],
      {'session_token': sessionToken},
    );
    final response = await _get(uri);

    return _parseSelectedPlace(response.body);
  }

  Future<Ride> createRide({
    required String title,
    required String rideDate,
    required String departureTime,
    required SelectedPlace startPlace,
    required SelectedPlace destinationPlace,
    String? briefingTime,
    double? toll,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'ride_date': rideDate,
      'departure_time': departureTime,
      'start_name': startPlace.displayName,
      'start_lat': startPlace.lat,
      'start_lng': startPlace.lng,
      'dest_name': destinationPlace.displayName,
      'dest_lat': destinationPlace.lat,
      'dest_lng': destinationPlace.lng,
    };

    if (briefingTime != null) {
      payload['briefing_time'] = briefingTime;
    }

    if (toll != null) {
      payload['toll'] = toll;
    }

    final response = await _post(_uri('/rides'), payload);

    return _parseRide(response.body);
  }

  Future<http.Response> _get(Uri uri) async {
    return _send(() {
      return _client.get(uri, headers: const {'Accept': 'application/json'});
    }, expectedStatusCodes: const [200]);
  }

  Future<http.Response> _post(Uri uri, Map<String, dynamic> payload) async {
    return _send(() {
      return _client.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
    }, expectedStatusCodes: const [200, 201]);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    required List<int> expectedStatusCodes,
  }) async {
    try {
      final response = await request();

      if (!expectedStatusCodes.contains(response.statusCode)) {
        throw RideApiException(
          _errorMessage(response),
          statusCode: response.statusCode,
        );
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
    final segments = path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);

    return _uriFromSegments(segments, queryParameters);
  }

  Uri _uriFromSegments(
    List<String> segments, [
    Map<String, String>? queryParameters,
  ]) {
    return _baseUri.replace(
      pathSegments: [..._baseSegments, ...segments],
      queryParameters: queryParameters,
    );
  }

  List<Ride> _parseRides(String body) => _parseList(body, Ride.fromJson);

  List<City> _parseCities(String body) => _parseList(body, City.fromJson);

  List<PlaceSuggestion> _parsePlaceSuggestions(String body) {
    return _parseList(body, PlaceSuggestion.fromJson);
  }

  SelectedPlace _parseSelectedPlace(String body) {
    return _parseItem(body, SelectedPlace.fromJson);
  }

  Ride _parseRide(String body) => _parseItem(body, Ride.fromJson);

  List<T> _parseList<T>(String body, T Function(Map<String, dynamic>) fromJson) {
    final data = _decode(body)['data'];

    if (data is! List) {
      throw const RideApiException('Resposta inválida da API.');
    }

    try {
      return [for (final item in data) fromJson(_asJsonObject(item))];
    } catch (_) {
      throw const RideApiException('Resposta inválida da API.');
    }
  }

  T _parseItem<T>(String body, T Function(Map<String, dynamic>) fromJson) {
    try {
      return fromJson(_asJsonObject(_decode(body)['data']));
    } catch (_) {
      throw const RideApiException('Resposta inválida da API.');
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final message = _decode(response.body)['message'];

      if (message is String && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Sem corpo JSON utilizável; usa o status code abaixo.
    }

    return 'A API respondeu com ${response.statusCode}.';
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return _asJsonObject(jsonDecode(body));
    } catch (_) {
      throw const RideApiException('Resposta inválida da API.');
    }
  }

  Map<String, dynamic> _asJsonObject(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    throw const RideApiException('Resposta inválida da API.');
  }
}

class RideApiException implements Exception {
  const RideApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
