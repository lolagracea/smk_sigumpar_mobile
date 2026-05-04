import 'package:flutter/material.dart';
import '../constants/route_names.dart';
import '../models/menu_item_model.dart';
import '../utils/role_helper.dart';

/// ─────────────────────────────────────────────────────────────────
/// ScoutMenuConfig — konfigurasi menu PRAMUKA (SCOUT)
///
/// ⚠️ ATURAN KETAT:
/// - Menu HARUS sesuai fitur pramuka di web existing
/// - Tidak boleh tambah menu yang tidak ada di web
/// - Tidak boleh hapus menu yang ada di web
/// - Urutan mengikuti navigasi web PRAMUKA
///
/// Web existing fitur PRAMUKA:
///   1. Beranda (Dashboard)
///   2. Kelas Pramuka (Scout Groups / Regu)
///   3. Absensi Pramuka (Scout Attendance)
///   4. Laporan Kegiatan (Activity Report)
///   5. Profil
///
/// MULTI-ROLE: Menu di sini ditetapkan untuk role [pramuka].
/// Jika user punya role lain (misal: pramuka + guru-mapel),
/// menu pramuka tetap tampil selama roles mengandung 'pramuka'.
/// ─────────────────────────────────────────────────────────────────
class ScoutMenuConfig {
  ScoutMenuConfig._();

  /// Menu utama untuk modul PRAMUKA
  static const List<MenuItemModel> menus = [
    // ── UTAMA ────────────────────────────────────────────────
    MenuItemModel(
      id: 'home',
      label: 'Beranda',
      icon: Icons.home_filled,
      route: RouteNames.home,
      allowedRoles: [AppRoles.pramuka],
    ),

    // ── MODUL PRAMUKA (sesuai urutan web) ────────────────────
    MenuItemModel(
      id: 'scout_classes',
      label: 'Kelas Pramuka',
      icon: Icons.groups_rounded,
      route: RouteNames.scoutClasses,
      allowedRoles: [AppRoles.pramuka],
    ),
    MenuItemModel(
      id: 'scout_attendance',
      label: 'Absensi Pramuka',
      icon: Icons.fact_check_rounded,
      route: RouteNames.scoutAttendance,
      allowedRoles: [AppRoles.pramuka],
    ),
    MenuItemModel(
      id: 'scout_report',
      label: 'Laporan Kegiatan',
      icon: Icons.assignment_rounded,
      route: RouteNames.scoutReport,
      allowedRoles: [AppRoles.pramuka],
    ),

    // ── AKUN ──────────────────────────────────────────────────
    MenuItemModel(
      id: 'profile',
      label: 'Profil Saya',
      icon: Icons.person_outline_rounded,
      route: RouteNames.profile,
      allowedRoles: [AppRoles.pramuka],
    ),
  ];

  /// ✅ MULTI-ROLE: Filter menu berdasarkan SEMUA role user.
  ///
  /// Tampilkan menu jika user punya setidaknya satu role
  /// yang cocok dengan allowedRoles menu tersebut.
  static List<MenuItemModel> getMenusForRoles(List<String> userRoles) {
    if (userRoles.isEmpty) return [];
    return menus.where((m) => m.isAccessibleByAny(userRoles)).toList();
  }

  /// @deprecated Gunakan [getMenusForRoles] untuk multi-role support.
  /// Backward compat: filter menu berdasarkan single role string.
  static List<MenuItemModel> getMenusForRole(String? role) {
    if (role == null) return [];
    return getMenusForRoles([role]);
  }

  /// Cek apakah user (dengan multi-role) punya akses ke modul pramuka
  static bool hasPramukaAccess(List<String> userRoles) {
    return RoleHelper.hasRole(
      targetRole: AppRoles.pramuka,
      roles: userRoles,
    );
  }
}
