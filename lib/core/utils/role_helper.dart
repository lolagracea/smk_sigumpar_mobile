import '../constants/route_names.dart';

class AppRoles {
  AppRoles._();

  static const String principal     = 'kepala-sekolah';
  static const String vicePrincipal = 'waka-sekolah';
  static const String teacher       = 'guru-mapel';
  static const String homeroom      = 'wali-kelas';
  static const String staff         = 'tata-usaha';
  static const String vokasi        = 'vokasi';

  /// 🎯 Role utama
  static const String pramuka       = 'pramuka';
}

class RoleHelper {
  RoleHelper._();

  static bool isPramuka(String? role) => role == AppRoles.pramuka;

  static bool hasRole(String? userRole, List<String> allowedRoles) {
    if (userRole == null) return false;
    return allowedRoles.contains(userRole);
  }

  // Optional: kalau memang sudah tidak dipakai, bisa dihapus juga
  static bool isPrincipal(String? role) =>
      role == AppRoles.principal || role == AppRoles.vicePrincipal;

  static bool isTeacher(String? role) =>
      role == AppRoles.teacher || role == AppRoles.homeroom;

  static bool isStaff(String? role) =>
      role == AppRoles.staff;

  static String getHomeRouteByRole(String? role) {
    return RouteNames.home;
  }

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
}