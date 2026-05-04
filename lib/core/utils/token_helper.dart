import 'dart:convert';

class TokenHelper {
  TokenHelper._();

  // ═══════════════════════════════════════════════════════════════
  // === CORE METHODS (existing — tidak diubah) ===
  // ═══════════════════════════════════════════════════════════════

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

  /// Cek apakah token akan expire dalam N menit ke depan
  static bool willExpireSoon(String token, {int minutes = 5}) {
    final payload = decodePayload(token);
    if (payload == null) return true;

    final exp = payload['exp'];
    if (exp == null) return false;

    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiry.subtract(Duration(minutes: minutes)));
  }

  // ═══════════════════════════════════════════════════════════════
  // === LEGACY METHODS (existing — tetap dipertahankan) ===
  // ═══════════════════════════════════════════════════════════════

  /// Ambil role dari token (legacy — single role claim)
  ///
  /// ⚠️ DEPRECATED: Keycloak tidak menggunakan single 'role' claim.
  /// Gunakan [getPrimaryRole] atau [getRoles] untuk extract role Keycloak.
  /// Method ini dipertahankan untuk backward compatibility.
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

  // ═══════════════════════════════════════════════════════════════
  // === KEYCLOAK ROLE EXTRACTION (NEW — yang dipakai sekarang) ===
  // ═══════════════════════════════════════════════════════════════

  /// Default Keycloak roles yang harus di-filter (bukan business roles)
  static const Set<String> _defaultKeycloakRoles = {
    'offline_access',
    'uma_authorization',
    'default-roles-smk-sigumpar',
  };

  /// Extract SEMUA roles dari JWT (Keycloak format).
  ///
  /// Membaca dari:
  /// 1. `realm_access.roles` (Keycloak realm-level roles)
  /// 2. `resource_access.smk-sigumpar.roles` (client-level roles)
  ///
  /// Default Keycloak roles otomatis di-filter.
  ///
  /// Returns empty list kalau tidak ada role atau token invalid.
  static List<String> getRoles(String token) {
    try {
      final payload = decodePayload(token);
      if (payload == null) return [];

      final allRoles = <String>{};

      // 1. Realm roles (standard Keycloak)
      final realmAccess = payload['realm_access'];
      if (realmAccess is Map && realmAccess['roles'] is List) {
        allRoles.addAll(
          (realmAccess['roles'] as List).map((r) => r.toString()),
        );
      }

      // 2. Client/Resource roles
      final resourceAccess = payload['resource_access'];
      if (resourceAccess is Map) {
        final clientAccess = resourceAccess['smk-sigumpar'];
        if (clientAccess is Map && clientAccess['roles'] is List) {
          allRoles.addAll(
            (clientAccess['roles'] as List).map((r) => r.toString()),
          );
        }
      }

      // Filter default Keycloak roles
      allRoles.removeWhere((r) => _defaultKeycloakRoles.contains(r));

      return allRoles.toList();
    } catch (_) {
      return [];
    }
  }

  /// Get primary role (yang paling penting) dari token.
  ///
  /// Berdasarkan priority order untuk SMK Sigumpar:
  /// kepala-sekolah > wakil-kepala-sekolah > waka-sekolah > tata-usaha
  /// > wali-kelas > guru-mapel > pramuka > vokasi > bendahara > siswa
  ///
  /// Kalau user punya multiple role, akan return yang priority tertinggi.
  /// Kalau tidak ada role yang match, return role pertama dari list.
  /// Kalau token invalid atau tidak punya role, return 'user'.
  static String getPrimaryRole(String token) {
    final roles = getRoles(token);
    if (roles.isEmpty) return 'user';

    // Priority order untuk SMK Sigumpar
    const priorityRoles = [
      'kepala-sekolah',
      'wakil-kepala-sekolah',
      'waka-sekolah',
      'tata-usaha',
      'wali-kelas',
      'guru-mapel',
      'pramuka',
      'vokasi',
      'bendahara',
      'siswa',
    ];

    for (final priorityRole in priorityRoles) {
      if (roles.contains(priorityRole)) return priorityRole;
    }

    // Kalau tidak match priority list, return role pertama
    return roles.first;
  }

  /// Cek apakah user punya role tertentu dari token
  static bool hasRole(String token, String role) {
    return getRoles(token).contains(role);
  }

  /// Cek apakah user punya salah satu dari roles list
  static bool hasAnyRole(String token, List<String> roles) {
    final userRoles = getRoles(token);
    return roles.any((r) => userRoles.contains(r));
  }

  /// Get username (preferred_username) dari token Keycloak
  static String? getUsernameFromToken(String token) {
    final payload = decodePayload(token);
    return payload?['preferred_username']?.toString();
  }

  /// Get email dari token
  static String? getEmailFromToken(String token) {
    final payload = decodePayload(token);
    return payload?['email']?.toString();
  }
}