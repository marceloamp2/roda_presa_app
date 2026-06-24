import 'json_parsers.dart';
import 'ride.dart';

class MyRides {
  const MyRides({required this.organized, required this.confirmed});

  final List<Ride> organized;
  final List<Ride> confirmed;

  factory MyRides.fromJson(Map<String, dynamic> json) {
    final data = asJsonObject(json['data']);

    return MyRides(
      organized: _parseRideList(data['organized']),
      confirmed: _parseRideList(data['confirmed']),
    );
  }

  static List<Ride> _parseRideList(dynamic value) {
    final list = switch (value) {
      {'data': final data} => data,
      _ => value,
    };

    if (list is! List) {
      return const [];
    }

    try {
      return [for (final item in list) Ride.fromJson(asJsonObject(item))];
    } catch (_) {
      throw const FormatException('Resposta de Meus roles inválida.');
    }
  }
}
