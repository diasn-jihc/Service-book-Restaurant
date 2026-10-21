String normalizePhone(String value) =>
    value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

bool isValidPhone(String value) =>
    RegExp(r'^\+?\d{10,15}$').hasMatch(normalizePhone(value));
