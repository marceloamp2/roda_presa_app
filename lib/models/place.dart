import 'json_parsers.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.name,
    required this.address,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String name;
  final String address;
  final String mainText;
  final String secondaryText;

  String get title => mainText.isNotEmpty ? mainText : name;

  String get subtitle {
    if (secondaryText.isNotEmpty) {
      return secondaryText;
    }

    return address;
  }

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: asString(json['place_id']),
      name: asString(json['name']),
      address: asString(json['address']),
      mainText: asString(json['main_text']),
      secondaryText: asString(json['secondary_text']),
    );
  }
}

class SelectedPlace {
  const SelectedPlace({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.googleMapsUri,
  });

  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String googleMapsUri;

  String get displayName {
    if (name.isNotEmpty) {
      return name;
    }

    return address;
  }

  String get displayAddress {
    if (address.isNotEmpty) {
      return address;
    }

    return name;
  }

  factory SelectedPlace.fromJson(Map<String, dynamic> json) {
    return SelectedPlace(
      placeId: asString(json['place_id']),
      name: asString(json['name']),
      address: asString(json['address']),
      lat: asDouble(json['lat']),
      lng: asDouble(json['lng']),
      googleMapsUri: asString(json['google_maps_uri']),
    );
  }
}
