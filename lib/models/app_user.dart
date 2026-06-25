import 'json_parsers.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.motorcycle,
    this.state,
    this.city,
  });

  final int id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? motorcycle;
  final String? state;
  final String? city;

  bool get hasMotorcycle => (motorcycle?.trim().isNotEmpty) ?? false;

  bool get hasCity => (city?.trim().isNotEmpty) ?? false;

  bool get needsOnboarding => !hasMotorcycle || !hasCity;

  String get firstName {
    final parts = _nameParts;
    return parts.isEmpty ? name.trim() : parts.first;
  }

  String get initials {
    final parts = _nameParts;

    if (parts.isEmpty) {
      return '?';
    }

    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';

    return '$first$last'.toUpperCase();
  }

  List<String> get _nameParts => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  String get cityAndState {
    final cleanCity = city?.trim() ?? '';
    final cleanState = state?.trim() ?? '';

    if (cleanCity.isEmpty && cleanState.isEmpty) {
      return 'Não informado';
    }

    if (cleanCity.isEmpty) {
      return cleanState;
    }

    if (cleanState.isEmpty) {
      return cleanCity;
    }

    return '$cleanCity, $cleanState';
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: asInt(json['id']),
      name: asRequiredString(json['name']),
      email: asRequiredString(json['email']),
      photoUrl: asNullableString(json['photo_url']),
      motorcycle: asNullableString(json['motorcycle']),
      state: asNullableString(json['state']),
      city: asNullableString(json['city']),
    );
  }
}
