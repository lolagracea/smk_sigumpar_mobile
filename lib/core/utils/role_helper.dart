import '../constants/route_names.dart';

class AppRoles {
  static const String admin = 'admin';
  static const String principal = 'principal';        // Kepala Sekolah
  static const String vicePrincipal = 'vice_principal'; // Wakasek
  static const String teacher = 'teacher';            // Guru
  static const String homeroom = 'homeroom';          // Wali Kelas
  static const String student = 'student';            // Siswa
  static const String staff = 'staff';                // Staf TU
  static const String treasurer = 'treasurer';        // Bendahara
}

class RoleHelper {
  RoleHelper._();

  static bool hasRole(String? userRole, List<String> allowedRoles) {
    if (userRole == null) return false;
    return allowedRoles.contains(userRole);
  }

  static bool isAdmin(String? role) => role == AppRoles.admin;
  static bool isPrincipal(String? role) => role == AppRoles.principal;
  static bool isTeacher(String? role) =>
      role == AppRoles.teacher || role == AppRoles.homeroom;
  static bool isStudent(String? role) => role == AppRoles.student;
  static bool isStaff(String? role) =>
      role == AppRoles.staff || role == AppRoles.treasurer;

  /// Redirect ke halaman home sesuai role
  static String getHomeRouteByRole(String? role) {
    switch (role) {
      case AppRoles.admin:
        return RouteNames.home;
      case AppRoles.principal:
        return RouteNames.home;
      case AppRoles.vicePrincipal:
        return RouteNames.home;
      case AppRoles.teacher:
      case AppRoles.homeroom:
        return RouteNames.home;
      case AppRoles.student:
        return RouteNames.home;
      case AppRoles.staff:
      case AppRoles.treasurer:
        return RouteNames.home;
      default:
        return RouteNames.login;
    }
  }

  /// Label nama role dalam Bahasa Indonesia
  static String getRoleLabel(String? role) {
    switch (role) {
      case AppRoles.admin: return 'Administrator';
      case AppRoles.principal: return 'Kepala Sekolah';
      case AppRoles.vicePrincipal: return 'Wakil Kepala Sekolah';
      case AppRoles.teacher: return 'Guru';
      case AppRoles.homeroom: return 'Wali Kelas';
      case AppRoles.student: return 'Siswa';
      case AppRoles.staff: return 'Staf TU';
      case AppRoles.treasurer: return 'Bendahara';
      default: return 'Pengguna';
    }
  }
}
