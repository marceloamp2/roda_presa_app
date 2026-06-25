import 'dart:math';

import '../theme/app_theme.dart';
import 'json_parsers.dart';
import 'place.dart';
import 'ride_user.dart';

class Ride {
  const Ride({
    required this.id,
    required this.title,
    required this.destination,
    required this.departureName,
    required this.departureDetail,
    required this.time,
    required this.weekday,
    required this.date,
    required this.fullDate,
    required this.distanceKm,
    required this.confirmedCount,
    required this.users,
    required this.hot,
    required this.canceled,
    required this.briefing,
    required this.tolls,
    required this.notes,
    required this.editData,
  });

  final int id;
  final String title;
  final String destination;
  final String departureName;
  final String departureDetail;
  final String time;
  final String weekday;
  final String date;
  final String fullDate;
  final int distanceKm;
  final int confirmedCount;
  final List<RideUser> users;
  final bool hot;
  final bool canceled;
  final String briefing;
  final String tolls;
  final String notes;
  final RideEditData editData;

  String get departureSummary {
    if (departureDetail.isEmpty) {
      return departureName;
    }

    return '$departureName, $departureDetail';
  }

  String get webUrl => 'https://rodapresa.com.br/rides/$id';

  String get shareText {
    return '''🏍️ Rolê de moto 🏍️
🗓️ Data: $fullDate
🚩 Destino: $destination
🚏 Saída: $departureName
⌚ Briefing: $briefing
⏰ Saída às $time
🛣️ Distância: ${distanceKm}km
💵 Pedágios: $tolls

👉 $webUrl''';
  }

  int get baseConfirmedCount => max(confirmedCount, users.length);

  factory Ride.fromJson(Map<String, dynamic> json) {
    final rideDate = _parseDate(json['ride_date'] as String);
    final users = _parseUsers(json['confirmations']);
    final place = _splitPlace(json['start_name'] as String);

    return Ride(
      id: json['id'] as int,
      title: json['title'] as String,
      destination: json['dest_name'] as String,
      departureName: place.first,
      departureDetail: place.length > 1 ? place.last : '',
      time: _formatTime(json['departure_time'] as String),
      weekday: _shortWeekday(rideDate),
      date: _shortDate(rideDate),
      fullDate: _fullDate(rideDate),
      distanceKm: _asRoundedInt(json['distance_km']),
      confirmedCount: _confirmedCount(json['confirmations_count'], users),
      users: users,
      hot: json['hot'] as bool? ?? false,
      canceled: json['status'] == 'canceled',
      briefing: _nullableTime(json['briefing_time']) ?? 'Não informado',
      tolls: _formatToll(json['toll']),
      notes: _formatNotes(json['notes']),
      editData: RideEditData.fromJson(json),
    );
  }

  static List<RideUser> _parseUsers(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(RideUser.fromJson)
        .toList(growable: false);
  }

  static int _confirmedCount(dynamic value, List<RideUser> users) {
    if (value == null) {
      return users.length;
    }

    return _asRoundedInt(value);
  }

  static DateTime _parseDate(String value) {
    final parts = value.split('-').map(int.parse).toList();

    return DateTime(parts[0], parts[1], parts[2]);
  }

  static String _shortDate(DateTime date) {
    return '${AppDateStrings.twoDigits(date.day)}/${AppDateStrings.twoDigits(date.month)}';
  }

  static String _fullDate(DateTime date) {
    return '${_shortDate(date)} ${_fullWeekday(date)}';
  }

  static String _shortWeekday(DateTime date) {
    return AppDateStrings.weekdays[date.weekday - 1];
  }

  static String _fullWeekday(DateTime date) {
    return AppDateStrings.weekdaysFull[date.weekday - 1];
  }

  static String _formatTime(String value) {
    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  static String? _nullableTime(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return _formatTime(value);
  }

  static String _formatToll(dynamic value) {
    if (value == null) {
      return 'sem pedágio';
    }

    final amount = _asDouble(value);

    if (amount == 0) {
      return 'sem pedágio';
    }

    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String _formatNotes(dynamic value) {
    if (value is! String) {
      return '';
    }

    return value.trim();
  }

  static int _asRoundedInt(dynamic value) {
    return _asDouble(value).round();
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.parse(value);
    }

    return 0;
  }

  static List<String> _splitPlace(String value) {
    final separator = value.contains(' - ') ? ' - ' : ',';
    final parts = value
        .split(separator)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return parts.isEmpty ? [value] : parts;
  }
}

/// Raw ride values used to prefill the edit form.
class RideEditData {
  const RideEditData({
    required this.title,
    required this.rideDate,
    required this.briefingTime,
    required this.departureTime,
    required this.startName,
    required this.startLat,
    required this.startLng,
    required this.destName,
    required this.destLat,
    required this.destLng,
    required this.toll,
    required this.notes,
  });

  final String title;
  final String rideDate;
  final String? briefingTime;
  final String? departureTime;
  final String startName;
  final double startLat;
  final double startLng;
  final String destName;
  final double destLat;
  final double destLng;
  final double? toll;
  final String notes;

  SelectedPlace get startPlace => _placeFrom(startName, startLat, startLng);

  SelectedPlace get destinationPlace => _placeFrom(destName, destLat, destLng);

  SelectedPlace _placeFrom(String name, double lat, double lng) {
    return SelectedPlace(
      placeId: '',
      name: name,
      address: '',
      lat: lat,
      lng: lng,
      googleMapsUri: '',
    );
  }

  factory RideEditData.fromJson(Map<String, dynamic> json) {
    return RideEditData(
      title: asString(json['title']),
      rideDate: asString(json['ride_date']),
      briefingTime: asNullableString(json['briefing_time']),
      departureTime: asNullableString(json['departure_time']),
      startName: asString(json['start_name']),
      startLat: asDouble(json['start_lat']),
      startLng: asDouble(json['start_lng']),
      destName: asString(json['dest_name']),
      destLat: asDouble(json['dest_lat']),
      destLng: asDouble(json['dest_lng']),
      toll: asNullableDouble(json['toll']),
      notes: asString(json['notes']),
    );
  }
}
