import 'package:flutter/material.dart';
import '../constants/route_names.dart';
import '../models/menu_item_model.dart';
import '../utils/role_helper.dart';

/// ─────────────────────────────────────────────────────────────────
/// ScoutMenuConfig — konfigurasi menu PRAMUKA (SCOUT)
///
/// Menu yang tersedia (sesuai web):
///   1. Beranda (Dashboard)
///   2. Absensi Pramuka (Scout Attendance)
///   3. Laporan Kegiatan (Activity Report)
///   4. Profil
///
/// CATATAN: Kelas Pramuka DIHAPUS — tidak ada di web (source of truth)
/// ─────────────────────────────────────────────────────────────────
class ScoutMenuConfig {
  ScoutMenuConfig._();

  static const List<MenuItemModel> menus = [
    // ── UTAMA ────────────────────────────────────────────────
    MenuItemModel(
      id: 'home',
      label: 'Beranda',
      icon: Icons.home_filled,
      route: RouteNames.home,
      allowedRoles: [AppRoles.pramuka],
    ),

    // ── MODUL PRAMUKA ─────────────────────────────────────────
    // 'scout_classes' DIHAPUS — Kelas Pramuka tidak ada di web
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

  /// Filter menu berdasarkan semua role user (multi-role support).
  static List<MenuItemModel> getMenusForRoles(List<String> userRoles) {
    if (userRoles.isEmpty) return [];
    return menus.where((m) => m.isAccessibleByAny(userRoles)).toList();
  }

  /// @deprecated — gunakan [getMenusForRoles].
  static List<MenuItemModel> getMenusForRole(String? role) {
    if (role == null) return [];
    return getMenusForRoles([role]);
  }

  static bool hasPramukaAccess(List<String> userRoles) {
    return RoleHelper.hasAccess(userRoles, [AppRoles.pramuka]);
  }
}