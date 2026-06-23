import 'json_parsers.dart';

class City {
  const City({
    required this.id,
    required this.name,
    required this.state,
    required this.lat,
    required this.lng,
  });

  final int id;
  final String name;
  final String state;
  final double lat;
  final double lng;

  String get displayName => '$name, $state';

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: asInt(json['id']),
      name: json['name'] as String,
      state: json['state'] as String,
      lat: asDouble(json['lat']),
      lng: asDouble(json['lng']),
    );
  }
}
