String asString(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString();
}

int asInt(dynamic value) {
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

double asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.parse(value);
  }

  throw const FormatException('Invalid decimal value.');
}

Map<String, dynamic> asJsonObject(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  throw const FormatException('Invalid JSON object.');
}

String asRequiredString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  throw const FormatException('Missing required string value.');
}

String? asNullableString(dynamic value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return value;
}

double? asNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  return asDouble(value);
}
