import '../constants/route_names.dart';

/// ─────────────────────────────────────────────────────────────
/// AppRoles — konstanta semua role di sistem SMK Sigumpar
///
/// ⚠️ ATURAN: Nilai string HARUS sama persis dengan yang ada
/// di Keycloak realm & backend web (case-sensitive).
/// ─────────────────────────────────────────────────────────────
class AppRoles {
  AppRoles._();

  static const String principal     = 'kepala-sekolah';
  static const String vicePrincipal = 'waka-sekolah';
  static const String teacher       = 'guru-mapel';
  static const String homeroom      = 'wali-kelas';
  static const String staff         = 'tata-usaha';
  static const String vokasi        = 'vokasi';

  /// 🎯 Role utama yang sedang dikembangkan di mobile
  static const String pramuka       = 'pramuka';

  /// Daftar semua role yang dikenali sistem
  static const List<String> all = [
    principal,
    vicePrincipal,
    teacher,
    homeroom,
    staff,
    vokasi,
    pramuka,
  ];
}

/// ─────────────────────────────────────────────────────────────
/// RoleHelper — utility untuk RBAC (Role-Based Access Control)
///
/// PERUBAHAN dari versi lama:
/// - Semua method kini support MULTI-ROLE (List<String>)
/// - `hasRole(String?, List<String>)` → single role check (legacy)
/// - `hasAccess(List<String>, List<String>)` → MULTI-ROLE check (baru)
/// - Backward compatible: method lama tetap ada
/// ─────────────────────────────────────────────────────────────
class RoleHelper {
  RoleHelper._();

  // ─── MULTI-ROLE ACCESS CHECK (utama, pakai ini) ──────────

  /// Cek apakah user (dengan banyak role) punya akses ke resource.
  ///
  /// Returns true kalau ada IRISAN antara [userRoles] dan [allowedRoles].
  ///
  /// Contoh:
  /// ```dart
  /// // User punya role [pramuka, guru-mapel]
  /// // Menu hanya untuk [pramuka]
  /// RoleHelper.hasAccess(['pramuka', 'guru-mapel'], ['pramuka']); // → true
  ///
  /// // User punya role [tata-usaha]
  /// // Menu hanya untuk [pramuka]
  /// RoleHelper.hasAccess(['tata-usaha'], ['pramuka']); // → false
  /// ```
  static bool hasAccess(
    List<String> userRoles,
    List<String> allowedRoles,
  ) {
    if (userRoles.isEmpty || allowedRoles.isEmpty) return false;
    return allowedRoles.any((role) => userRoles.contains(role));
  }

  /// Filter list menu berdasarkan semua role user.
  ///
  /// Generik — bekerja dengan object apapun selama ada callback [getRoles].
  ///
  /// Contoh:
  /// ```dart
  /// final visibleMenus = RoleHelper.filterByRoles(
  ///   items: allMenus,
  ///   userRoles: user.roles,
  ///   getAllowedRoles: (menu) => menu.allowedRoles,
  /// );
  /// ```
  static List<T> filterByRoles<T>({
    required List<T> items,
    required List<String> userRoles,
    required List<String> Function(T item) getAllowedRoles,
  }) {
    return items
        .where((item) => hasAccess(userRoles, getAllowedRoles(item)))
        .toList();
  }

  // ─── SINGLE-ROLE CHECKS (backward compat / utility) ──────

  /// @deprecated Gunakan [hasAccess] untuk multi-role.
  /// Cek apakah single role ada dalam daftar allowedRoles.
  static bool hasRole(String? userRole, List<String> allowedRoles) {
    if (userRole == null) return false;
    return allowedRoles.contains(userRole);
  }

  static bool isPramuka(String? role) => role == AppRoles.pramuka;

  static bool isPrincipal(String? role) =>
      role == AppRoles.principal || role == AppRoles.vicePrincipal;

  static bool isTeacher(String? role) =>
      role == AppRoles.teacher || role == AppRoles.homeroom;

  static bool isStaff(String? role) => role == AppRoles.staff;

  // ─── ROUTING ─────────────────────────────────────────────

  /// Semua role saat ini diarahkan ke HomeScreen setelah login.
  /// Drawer di HomeScreen yang akan menyesuaikan menu per role.
  static String getHomeRouteByRole(String? role) {
    return RouteNames.home;
  }

  // ─── LABEL ───────────────────────────────────────────────

  /// Label human-readable untuk ditampilkan di UI
  static String getRoleLabel(String? role) {
    switch (role) {
      case AppRoles.principal:     return 'Kepala Sekolah';
      case AppRoles.vicePrincipal: return 'Waka Sekolah';
      case AppRoles.teacher:       return 'Guru Mapel';
      case AppRoles.homeroom:      return 'Wali Kelas';
      case AppRoles.staff:         return 'Tata Usaha';
      case AppRoles.pramuka:       return 'Pembina Pramuka';
      case AppRoles.vokasi:        return 'Kajur Vokasi';
      default:                     return 'Pengguna';
    }
  }

  /// Label untuk daftar role (multi-role), dipisah koma
  static String getRolesLabel(List<String> roles) {
    if (roles.isEmpty) return 'Pengguna';
    return roles.map(getRoleLabel).join(', ');
  }
}