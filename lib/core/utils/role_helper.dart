import 'package:flutter/material.dart';

class DrawerMenu {
  final String title;
  final IconData icon;
  final String? route;
  final List<DrawerMenu>? children;

  const DrawerMenu({
    required this.title,
    required this.icon,
    this.route,
    this.children,
  });
}

class RoleHelper {
  RoleHelper._();

  static String getRoleLabel(String? role) {
    switch (role) {
      case 'tata-usaha':
        return 'Tata Usaha';
      case 'kepala-sekolah':
        return 'Kepala Sekolah';
      case 'waka-sekolah':
        return 'Waka Sekolah';
      case 'guru-mapel':
        return 'Guru Mapel';
      case 'wali-kelas':
        return 'Wali Kelas';
      case 'vokasi':
        return 'Vokasi';
      case 'pramuka':
        return 'Pramuka';
      default:
        return 'User';
    }
  }

  static List<DrawerMenu> getDrawerMenus(String? role) {
    switch (role) {
      case 'tata-usaha':
        return _tataUsahaMenus();

      case 'kepala-sekolah':
        return _kepalaSekolahMenus();

      case 'waka-sekolah':
        return _wakaSekolahMenus();

      case 'guru-mapel':
        return _guruMapelMenus();

      case 'wali-kelas':
        return _waliKelasMenus();

      case 'vokasi':
        return _vokasiMenus();

      case 'pramuka':
        return _pramukaMenus();

      default:
        return _defaultMenus();
    }
  }

  static List<DrawerMenu> getMenusForRoles(List<String> roles) {
    if (roles.isEmpty) return _defaultMenus();

    final merged = <DrawerMenu>[];
    final addedKeys = <String>{};

    for (final role in roles) {
      final menus = getDrawerMenus(role);

      for (final menu in menus) {
        final key = '${menu.title}-${menu.route ?? ''}';

        if (!addedKeys.contains(key)) {
          merged.add(menu);
          addedKeys.add(key);
        }
      }
    }

    return merged.isEmpty ? _defaultMenus() : merged;
  }

  static List<DrawerMenu> _defaultMenus() {
    return const [
      DrawerMenu(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        route: '/dashboard',
      ),
    ];
  }

  static List<DrawerMenu> _tataUsahaMenus() {
    return const [
      DrawerMenu(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        route: '/dashboard',
      ),
      DrawerMenu(
        title: 'Manajemen Akademik',
        icon: Icons.school_outlined,
        children: [
          DrawerMenu(
            title: 'Manajemen Kelas',
            icon: Icons.class_outlined,
            route: '/academic/classes',
          ),
          DrawerMenu(
            title: 'Manajemen Siswa',
            icon: Icons.groups_outlined,
            route: '/academic/students',
          ),
          DrawerMenu(
            title: 'Pengumuman',
            icon: Icons.campaign_outlined,
            route: '/academic/announcements',
          ),
          DrawerMenu(
            title: 'Arsip Surat',
            icon: Icons.folder_copy_outlined,
            route: '/academic/letters',
          ),
          DrawerMenu(
            title: 'Jadwal Mengajar',
            icon: Icons.calendar_month_outlined,
            route: '/academic/schedules',
          ),
          DrawerMenu(
            title: 'Jadwal Piket',
            icon: Icons.fact_check_outlined,
            route: '/academic/picket',
          ),
          DrawerMenu(
            title: 'Jadwal Upacara',
            icon: Icons.flag_outlined,
            route: '/academic/ceremony',
          ),
        ],
      ),
    ];
  }

  static List<DrawerMenu> _kepalaSekolahMenus() {
    return const [
      DrawerMenu(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        route: '/dashboard',
      ),
      DrawerMenu(
        title: 'Monitoring Sekolah',
        icon: Icons.monitor_heart_outlined,
        children: [
          DrawerMenu(
            title: 'Rekap Absensi Siswa',
            icon: Icons.assignment_ind_outlined,
            route: '/student/attendance-recap',
          ),
          DrawerMenu(
            title: 'Rekap Absensi Guru',
            icon: Icons.badge_outlined,
            route: '/learning/teacher-attendance-recap',
          ),
          DrawerMenu(
            title: 'Evaluasi Kinerja Guru',
            icon: Icons.rate_review_outlined,
            route: '/learning/teacher-evaluation',
          ),
          DrawerMenu(
            title: 'Review Perangkat',
            icon: Icons.description_outlined,
            route: '/learning/devices-review',
          ),
        ],
      ),
    ];
  }

  static List<DrawerMenu> _wakaSekolahMenus() {
    return const [
      DrawerMenu(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        route: '/dashboard',
      ),
      DrawerMenu(
        title: 'Monitoring Waka',
        icon: Icons.analytics_outlined,
        children: [
          DrawerMenu(
            title: 'Kurikulum',
            icon: Icons.menu_book_outlined,
            route: '/waka/curriculum',
          ),
          DrawerMenu(
            title: 'Monitoring Absensi Guru',
            icon: Icons.badge_outlined,
            route: '/learning/teacher-attendance-recap',
          ),
          DrawerMenu(
            title: 'Monitoring Jadwal',
            icon: Icons.calendar_month_outlined,
            route: '/academic/schedules',
          ),
          DrawerMenu(
            title: 'Monitoring Perangkat',
            icon: Icons.description_outlined,
            route: '/learning/devices-review',
          ),
          DrawerMenu(
            title: 'Monitoring Parenting',
            icon: Icons.family_restroom_outlined,
            route: '/student/parenting',
          ),
          DrawerMenu(
            title: 'Laporan Ringkas',
            icon: Icons.summarize_outlined,
            route: '/waka/summary',
          ),
        ],
      ),
    ];
  }

  static List<DrawerMenu> _guruMapelMenus() {
    return const [
      DrawerMenu(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        route: '/dashboard',
      ),
      DrawerMenu(
        title: 'Guru Mapel',
        icon: Icons.person_pin_outlined,
        children: [
          DrawerMenu(
            title: 'Input Nilai',
            icon: Icons.edit_note_outlined,
            route: '/guru-mapel/grades',
          ),
          DrawerMenu(
            title: 'Absensi Siswa',
            icon: Icons.how_to_reg_outlined,
            route: '/guru-mapel/student-attendance',
          ),
          DrawerMenu(
            title: 'Jadwal Mengajar',
            icon: Icons.calendar_today_outlined,
            route: '/guru-mapel/schedule',
          ),
          DrawerMenu(
            title: 'Catatan Mengajar',
            icon: Icons.note_alt_outlined,
            route: '/learning/teaching-notes',
          ),
          DrawerMenu(
            title: 'Perangkat Pembelajaran',
            icon: Icons.description_outlined,
            route: '/learning/devices',
          ),
          DrawerMenu(
            title: 'Absensi Guru',
            icon: Icons.badge_outlined,
            route: '/learning/teacher-attendance',
          ),
        ],
      ),
    ];
  }

  static List<DrawerMenu> _waliKelasMenus() {
    return const [
      DrawerMenu(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        route: '/dashboard',
      ),
      DrawerMenu(
        title: 'Wali Kelas',
        icon: Icons.supervisor_account_outlined,
        children: [
          DrawerMenu(
            title: 'Presensi Kelas',
            icon: Icons.how_to_reg_outlined,
            route: '/wali-kelas/attendance',
          ),
          DrawerMenu(
            title: 'Kebersihan Kelas',
            icon: Icons.cleaning_services_outlined,
            route: '/student/cleanliness',
          ),
          DrawerMenu(
            title: 'Parenting',
            icon: Icons.family_restroom_outlined,
            route: '/student/parenting',
          ),
          DrawerMenu(
            title: 'Refleksi Wali Kelas',
            icon: Icons.forum_outlined,
            route: '/student/reflection',
          ),
          DrawerMenu(
            title: 'Surat Panggilan',
            icon: Icons.mark_email_unread_outlined,
            route: '/student/summons',
          ),
        ],
      ),
    ];
  }

  static List<DrawerMenu> _vokasiMenus() {
    return const [
      DrawerMenu(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        route: '/dashboard',
      ),
      DrawerMenu(
        title: 'Vokasi / PKL',
        icon: Icons.work_outline,
        children: [
          DrawerMenu(
            title: 'Lokasi PKL',
            icon: Icons.location_on_outlined,
            route: '/vokasi/pkl/lokasi',
          ),
          DrawerMenu(
            title: 'Progres PKL',
            icon: Icons.timeline_outlined,
            route: '/vokasi/pkl/progres',
          ),
          DrawerMenu(
            title: 'Nilai PKL',
            icon: Icons.grade_outlined,
            route: '/vokasi/pkl/nilai',
          ),
        ],
      ),
    ];
  }

  static List<DrawerMenu> _pramukaMenus() {
    return const [
      DrawerMenu(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        route: '/dashboard',
      ),
      DrawerMenu(
        title: 'Pramuka',
        icon: Icons.emoji_flags_outlined,
        children: [
          DrawerMenu(
            title: 'Absensi Pramuka',
            icon: Icons.how_to_reg_outlined,
            route: '/pramuka/attendance',
          ),
          DrawerMenu(
            title: 'Silabus & Perangkat',
            icon: Icons.menu_book_outlined,
            route: '/pramuka/silabus',
          ),
          DrawerMenu(
            title: 'Laporan Kegiatan',
            icon: Icons.summarize_outlined,
            route: '/pramuka/laporan-kegiatan',
          ),
        ],
      ),
    ];
  }
}