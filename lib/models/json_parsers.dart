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
