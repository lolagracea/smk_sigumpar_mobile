import 'package:flutter/material.dart';
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

class DrawerMenuItem {
  final String title;
  final IconData icon;
  final String route;
  final List<DrawerMenuItem>? children; // <-- Ini yang menyimpan sub-menu

  DrawerMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    this.children,
  });
}

class RoleHelper {
  RoleHelper._();

  // Pengaman: Diubah ke huruf kecil semua agar TATA-USAHA dan tata-usaha dianggap sama
  static bool hasRole(String? userRole, List<String> allowedRoles) {
    if (userRole == null) return false;
    final roleStr = userRole.toLowerCase();
    return allowedRoles.any((r) => roleStr.contains(r.toLowerCase()));
  }

  static bool isAdmin(String? role) => hasRole(role, [AppRoles.admin]);
  static bool isPrincipal(String? role) => hasRole(role, [AppRoles.principal, AppRoles.vicePrincipal]);
  static bool isTeacher(String? role) => hasRole(role, [AppRoles.teacher]);
  static bool isHomeroom(String? role) => hasRole(role, [AppRoles.homeroom]);
  static bool isStudent(String? role) => hasRole(role, [AppRoles.student]);
  static bool isStaff(String? role) => hasRole(role, [AppRoles.staff, AppRoles.treasurer]);
  static bool isVocational(String? role) => hasRole(role, [AppRoles.vokasi, AppRoles.pramuka]);

  static String getHomeRouteByRole(String? role) {
    if (role == null) return RouteNames.login;
    if (hasRole(role, [
      AppRoles.admin, AppRoles.principal, AppRoles.vicePrincipal,
      AppRoles.teacher, AppRoles.homeroom, AppRoles.student,
      AppRoles.staff, AppRoles.treasurer, AppRoles.pramuka, AppRoles.vokasi
    ])) {
      return RouteNames.home;
    }
    return RouteNames.login;
  }

  static String getRoleLabel(String? role) {
    if (role == null) return 'Pengguna Umum';
    final r = role.toLowerCase();
    if (r.contains(AppRoles.admin)) return 'Administrator';
    if (r.contains(AppRoles.principal)) return 'Kepala Sekolah';
    if (r.contains(AppRoles.vicePrincipal)) return 'Waka Sekolah';
    if (r.contains(AppRoles.staff)) return 'Tata Usaha';
    if (r.contains(AppRoles.homeroom)) return 'Wali Kelas';
    if (r.contains(AppRoles.teacher)) return 'Guru Mapel';
    if (r.contains(AppRoles.student)) return 'Siswa';
    if (r.contains(AppRoles.vokasi)) return 'Kajur Vokasi';
    if (r.contains(AppRoles.pramuka)) return 'Pembina Pramuka';
    if (r.contains(AppRoles.treasurer)) return 'Bendahara';
    return 'Pengguna Umum';
  }

  // --- MENU DINAMIS BERDASARKAN ROLE ---
  static List<DrawerMenuItem> getDrawerMenus(String? role) {
    List<DrawerMenuItem> menus = [
      DrawerMenuItem(title: 'Dashboard Utama', icon: Icons.dashboard_rounded, route: RouteNames.home),
    ];

    if (role == null) return menus;

    // JIKA USER ADALAH TATA USAHA, BUAT FOLDER DROPDOWN
    if (isStaff(role)) {
      menus.add(
          DrawerMenuItem(
            title: 'Tata Usaha',
            icon: Icons.admin_panel_settings_rounded,
            route: '', // Kosong karena ini hanya folder, bukan link
            children: [
              DrawerMenuItem(title: 'Data Siswa', icon: Icons.people_alt_outlined, route: RouteNames.students),
              DrawerMenuItem(title: 'Data Guru', icon: Icons.person_search_outlined, route: RouteNames.teachers),
              DrawerMenuItem(title: 'Data Kelas & Mapel', icon: Icons.class_outlined, route: RouteNames.classes),
              DrawerMenuItem(title: 'Jadwal Pelajaran', icon: Icons.calendar_today_outlined, route: RouteNames.schedules),
              DrawerMenuItem(title: 'Pengumuman', icon: Icons.campaign_outlined, route: RouteNames.announcements),
              DrawerMenuItem(title: 'Arsip Surat', icon: Icons.mail_outline_rounded, route: RouteNames.letters),
            ],
          )
      );
    }

    return menus;
  }
}