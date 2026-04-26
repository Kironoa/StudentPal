import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Provides salted SHA-256 password hashing and secure salt generation.
class CryptoUtils {
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(saltBytes);
  }

  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  static String hashLegacy(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}