import '../constants/route_names.dart';

class AppRoles {
  static const String admin = 'admin';
  static const String principal = 'kepala-sekolah';
  static const String vicePrincipal = 'waka-sekolah';
  static const String teacher = 'guru-mapel';
  static const String homeroom = 'wali-kelas';
  static const String student = 'siswa';
  static const String staff = 'tata-usaha';
  static const String pramuka = 'pramuka';
  static const String vokasi = 'vokasi';
  static const String treasurer = 'bendahara';
}

class RoleHelper {
  RoleHelper._();

  static bool hasRole({
    required String targetRole,
    String? role,
    List<String>? roles,
  }) {
    final normalizedTarget = _normalizeRole(targetRole);

    if (normalizedTarget.isEmpty) {
      return false;
    }

    final normalizedUserRoles = getNormalizedRoles(
      role: role,
      roles: roles,
    );

    return normalizedUserRoles.contains(normalizedTarget);
  }

  static bool hasAnyRole({
    required List<String> targetRoles,
    String? role,
    List<String>? roles,
  }) {
    if (targetRoles.isEmpty) {
      return false;
    }

    return targetRoles.any(
          (targetRole) => hasRole(
        targetRole: targetRole,
        role: role,
        roles: roles,
      ),
    );
  }

  static List<String> getNormalizedRoles({
    String? role,
    List<String>? roles,
  }) {
    final result = <String>{};

    if (role != null && role.trim().isNotEmpty) {
      result.addAll(_splitRoles(role));
    }

    if (roles != null && roles.isNotEmpty) {
      for (final item in roles) {
        result.addAll(_splitRoles(item));
      }
    }

    return result.where((item) => item.isNotEmpty).toList();
  }

  static bool isTataUsaha({
    String? role,
    List<String>? roles,
  }) {
    return hasRole(
      targetRole: AppRoles.staff,
      role: role,
      roles: roles,
    );
  }

  static bool isGuruMapel({
    String? role,
    List<String>? roles,
  }) {
    return hasRole(
      targetRole: AppRoles.teacher,
      role: role,
      roles: roles,
    );
  }

  static bool isWaliKelas({
    String? role,
    List<String>? roles,
  }) {
    return hasRole(
      targetRole: AppRoles.homeroom,
      role: role,
      roles: roles,
    );
  }

  static bool isKepalaSekolah({
    String? role,
    List<String>? roles,
  }) {
    return hasRole(
      targetRole: AppRoles.principal,
      role: role,
      roles: roles,
    );
  }

  static bool isWakaSekolah({
    String? role,
    List<String>? roles,
  }) {
    return hasRole(
      targetRole: AppRoles.vicePrincipal,
      role: role,
      roles: roles,
    );
  }

  static bool isPramuka({
    String? role,
    List<String>? roles,
  }) {
    return hasRole(
      targetRole: AppRoles.pramuka,
      role: role,
      roles: roles,
    );
  }

  static bool isVokasi({
    String? role,
    List<String>? roles,
  }) {
    return hasRole(
      targetRole: AppRoles.vokasi,
      role: role,
      roles: roles,
    );
  }

  static bool isTreasurer({
    String? role,
    List<String>? roles,
  }) {
    return hasRole(
      targetRole: AppRoles.treasurer,
      role: role,
      roles: roles,
    );
  }

  static String getHomeRouteByRole(
      String? role, {
        List<String>? roles,
      }) {
    final normalizedRoles = getNormalizedRoles(
      role: role,
      roles: roles,
    );

    if (normalizedRoles.isEmpty) {
      return RouteNames.login;
    }

    return RouteNames.home;
  }

  static String getRoleLabel(String? role) {
    final normalizedRole = _normalizeRole(role ?? '');

    switch (normalizedRole) {
      case AppRoles.admin:
        return 'Administrator';
      case AppRoles.principal:
        return 'Kepala Sekolah';
      case AppRoles.vicePrincipal:
        return 'Waka Sekolah';
      case AppRoles.teacher:
        return 'Guru Mapel';
      case AppRoles.homeroom:
        return 'Wali Kelas';
      case AppRoles.student:
        return 'Siswa';
      case AppRoles.staff:
        return 'Tata Usaha';
      case AppRoles.pramuka:
        return 'Pembina Pramuka';
      case AppRoles.vokasi:
        return 'Kajur Vokasi';
      case AppRoles.treasurer:
        return 'Bendahara';
      default:
        if (role == null || role.trim().isEmpty) {
          return 'Pengguna Umum';
        }

        return _toTitleCase(
          role.trim().replaceAll('_', ' ').replaceAll('-', ' '),
        );
    }
  }

  static String getRolesLabel({
    String? role,
    List<String>? roles,
  }) {
    final normalizedRoles = getNormalizedRoles(
      role: role,
      roles: roles,
    );

    if (normalizedRoles.isEmpty) {
      return 'Pengguna Umum';
    }

    return normalizedRoles.map(getRoleLabel).join(', ');
  }

  static List<String> _splitRoles(String value) {
    return value
        .split(RegExp(r'[,;|]+'))
        .map(_normalizeRole)
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String _normalizeRole(String value) {
    return value.trim().toLowerCase().replaceAll('_', '-');
  }

  static String _toTitleCase(String value) {
    if (value.trim().isEmpty) {
      return value;
    }

    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
      if (word.length == 1) {
        return word.toUpperCase();
      }

      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}