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
      id: _asInt(json['id']),
      name: json['name'] as String,
      state: json['state'] as String,
      lat: _asDouble(json['lat']),
      lng: _asDouble(json['lng']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.parse(value);
    }

    throw const FormatException('Invalid integer value.');
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.parse(value);
    }

    throw const FormatException('Invalid decimal value.');
  }
}
