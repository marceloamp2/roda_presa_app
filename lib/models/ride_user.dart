class RideUser {
  const RideUser({
    required this.id,
    required this.name,
    required this.motorcycleSnapshot,
    required this.organizer,
  });

  final int id;
  final String name;
  final String? motorcycleSnapshot;
  final bool organizer;

  String get initials {
    final nameParts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (nameParts.isEmpty) {
      return '?';
    }

    final firstInitial = nameParts.first[0];
    final lastInitial = nameParts.length > 1 ? nameParts.last[0] : '';

    return '$firstInitial$lastInitial'.toUpperCase();
  }

  factory RideUser.fromJson(Map<String, dynamic> json) {
    return RideUser(
      id: json['id'] as int,
      name: json['name'] as String,
      motorcycleSnapshot: json['moto_snapshot'] as String?,
      organizer: json['organizer'] as bool? ?? false,
    );
  }
}
