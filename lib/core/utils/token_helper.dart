import 'dart:convert';

class TokenHelper {
  TokenHelper._();

  /// Decode JWT payload tanpa verify signature
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Cek apakah token sudah expired
  static bool isExpired(String token) {
    final payload = decodePayload(token);
    if (payload == null) return true;

    final exp = payload['exp'];
    if (exp == null) return false;

    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiry);
  }

  /// Ambil role dari token
  static String? getRoleFromToken(String token) {
    final payload = decodePayload(token);
    return payload?['role']?.toString();
  }

  /// Ambil user id dari token
  static String? getUserIdFromToken(String token) {
    final payload = decodePayload(token);
    return payload?['sub']?.toString() ?? payload?['id']?.toString();
  }

  /// Ambil nama dari token
  static String? getNameFromToken(String token) {
    final payload = decodePayload(token);
    return payload?['name']?.toString();
  }

  /// Cek apakah token akan expire dalam N menit ke depan
  static bool willExpireSoon(String token, {int minutes = 5}) {
    final payload = decodePayload(token);
    if (payload == null) return true;

    final exp = payload['exp'];
    if (exp == null) return false;

    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiry.subtract(Duration(minutes: minutes)));
  }
}
