import 'package:http/http.dart' as http;

import '../models/city.dart';
import '../models/json_parsers.dart';
import '../models/my_rides.dart';
import '../models/place.dart';
import '../models/ride.dart';
import 'api_client.dart';
import 'api_exception.dart';

class RideApiService {
  RideApiService({http.Client? client, String? baseUrl})
    : _apiClient = ApiClient(client: client, baseUrl: baseUrl);

  final ApiClient _apiClient;

  Future<List<Ride>> fetchRides({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final uri = _apiClient.uri('/rides', {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius_km': radiusKm.round().toString(),
    });

    final response = await _apiClient.get(uri);

    return _parseRides(response.body);
  }

  Future<Ride> fetchRide(int id) async {
    final response = await _apiClient.get(_apiClient.uri('/rides/$id'));

    return _parseRide(response.body);
  }

  Future<List<City>> searchCities({
    required String search,
    int limit = 20,
  }) async {
    final uri = _apiClient.uri('/cities', {
      'search': search,
      'limit': limit.toString(),
    });
    final response = await _apiClient.get(uri);

    return _parseCities(response.body);
  }

  Future<List<PlaceSuggestion>> autocompletePlaces({
    required String search,
    required String sessionToken,
    int limit = 5,
  }) async {
    final uri = _apiClient.uri('/places/autocomplete', {
      'search': search,
      'session_token': sessionToken,
      'limit': limit.toString(),
    });
    final response = await _apiClient.get(uri);

    return _parsePlaceSuggestions(response.body);
  }

  Future<SelectedPlace> fetchPlaceDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    final uri = _apiClient.uriFromSegments(
      ['places', placeId],
      {'session_token': sessionToken},
    );
    final response = await _apiClient.get(uri);

    return _parseSelectedPlace(response.body);
  }

  Future<Ride> createRide({
    required String authToken,
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

    final response = await _apiClient.post(
      _apiClient.uri('/rides'),
      payload,
      authToken: authToken,
    );

    return _parseRide(response.body);
  }

  Future<MyRides> fetchMyRides({required String authToken}) async {
    final response = await _apiClient.get(
      _apiClient.uri('/me/rides'),
      authToken: authToken,
    );

    return _parseMyRides(response.body);
  }

  void close() => _apiClient.close();

  List<Ride> _parseRides(String body) => _parseList(body, Ride.fromJson);

  List<City> _parseCities(String body) => _parseList(body, City.fromJson);

  List<PlaceSuggestion> _parsePlaceSuggestions(String body) {
    return _parseList(body, PlaceSuggestion.fromJson);
  }

  SelectedPlace _parseSelectedPlace(String body) {
    return _parseItem(body, SelectedPlace.fromJson);
  }

  Ride _parseRide(String body) => _parseItem(body, Ride.fromJson);

  MyRides _parseMyRides(String body) {
    try {
      return MyRides.fromJson(_apiClient.decode(body));
    } catch (_) {
      throw const ApiException('Resposta inválida da API.');
    }
  }

  List<T> _parseList<T>(
    String body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = _apiClient.decode(body)['data'];

    if (data is! List) {
      throw const ApiException('Resposta inválida da API.');
    }

    try {
      return [for (final item in data) fromJson(asJsonObject(item))];
    } catch (_) {
      throw const ApiException('Resposta inválida da API.');
    }
  }

  T _parseItem<T>(String body, T Function(Map<String, dynamic>) fromJson) {
    try {
      return fromJson(asJsonObject(_apiClient.decode(body)['data']));
    } catch (_) {
      throw const ApiException('Resposta inválida da API.');
    }
  }
}
