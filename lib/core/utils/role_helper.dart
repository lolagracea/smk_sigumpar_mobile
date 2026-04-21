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
  static const String treasurer = 'bendahara'; // 👈 Tambahan untuk menutupi error di bawah
}

class RoleHelper {
  RoleHelper._();

  /// Mengecek apakah user memiliki setidaknya satu role yang diizinkan
  static bool hasRole(String? userRole, List<String> allowedRoles) {
    if (userRole == null) return false;
    return allowedRoles.contains(userRole);
  }

  static bool isAdmin(String? role) => role == AppRoles.admin;
  static bool isPrincipal(String? role) =>
      role == AppRoles.principal || role == AppRoles.vicePrincipal;
  static bool isTeacher(String? role) =>
      role == AppRoles.teacher || role == AppRoles.homeroom;
  static bool isStudent(String? role) => role == AppRoles.student;
  static bool isStaff(String? role) =>
      role == AppRoles.staff || role == AppRoles.treasurer;

  /// Redirect ke halaman home sesuai role setelah login
  static String getHomeRouteByRole(String? role) {
    switch (role) {
      case AppRoles.admin:
      case AppRoles.principal:
      case AppRoles.vicePrincipal:
      case AppRoles.teacher:
      case AppRoles.homeroom:
      case AppRoles.student:
      case AppRoles.staff:
      case AppRoles.treasurer:
      case AppRoles.pramuka:
      case AppRoles.vokasi:
      // Semua role yang valid di atas akan diarahkan ke Home/Dashboard
        return RouteNames.home;
      default:
      // Jika tidak punya role / token bermasalah, kembalikan ke Login
        return RouteNames.login;
    }
  }

  /// Label nama role dalam Bahasa Indonesia (Untuk ditampilkan di UI Profil / Sidebar)
  static String getRoleLabel(String? role) {
    switch (role) {
      case AppRoles.admin: return 'Administrator';
      case AppRoles.principal: return 'Kepala Sekolah';
      case AppRoles.vicePrincipal: return 'Waka Sekolah';
      case AppRoles.teacher: return 'Guru Mapel';
      case AppRoles.homeroom: return 'Wali Kelas';
      case AppRoles.student: return 'Siswa';
      case AppRoles.staff: return 'Tata Usaha';
      case AppRoles.pramuka: return 'Pembina Pramuka';
      case AppRoles.vokasi: return 'Kajur Vokasi';
      case AppRoles.treasurer: return 'Bendahara';
      default: return 'Pengguna Umum';
    }
  }
}