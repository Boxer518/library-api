String normalizeIsbn(String value) {
  return value.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
}

String normalizeEmail(String value) {
  return value.trim().toLowerCase();
}
