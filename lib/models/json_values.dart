int jsonInt(Object? value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

String jsonString(Object? value, [String fallback = '']) {
  if (value is String) {
    return value;
  }
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

DateTime? jsonDate(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

List<int> jsonIntList(Object? value) {
  if (value is! List) {
    return const [];
  }
  final ids = <int>[];
  for (final item in value) {
    final id = jsonInt(item);
    if (id > 0) {
      ids.add(id);
    }
  }
  return ids;
}

String formatDate(DateTime value) {
  final utc = value.toUtc();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-${two(utc.day)}';
}

DateTime? parseDate(String? raw) {
  final text = raw?.trim() ?? '';
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  if (match == null) {
    return null;
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  final date = DateTime.utc(year, month, day);
  if (date.month != month || date.day != day) {
    return null;
  }
  return date;
}
