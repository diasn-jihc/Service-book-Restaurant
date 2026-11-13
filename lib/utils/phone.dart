/// Приводит номер к виду +77011234567.
String normalizePhone(String raw) {
  final s = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  if (s.startsWith('+')) return s;
  if (s.length == 11 && (s.startsWith('8') || s.startsWith('7'))) {
    return '+7${s.substring(1)}';
  }
  if (s.length == 10) return '+7$s';
  return s;
}

bool isValidPhone(String raw) =>
    RegExp(r'^\+\d{10,15}$').hasMatch(normalizePhone(raw));
