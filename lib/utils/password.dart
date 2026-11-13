import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Случайная «соль», чтобы одинаковые пароли хранились по-разному.
String makeSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64Url.encode(bytes);
}

/// Пароль в открытом виде не хранится — только его хеш.
String hashPassword(String password, String salt) {
  return sha256.convert(utf8.encode('$salt:$password')).toString();
}
