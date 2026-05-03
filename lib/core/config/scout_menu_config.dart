import 'package:flutter/material.dart';
import '../constants/route_names.dart';
import '../models/menu_item_model.dart';
import '../utils/role_helper.dart';

/// ─────────────────────────────────────────────────────────────
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
/// ─────────────────────────────────────────────────────────────
class ScoutMenuConfig {
  ScoutMenuConfig._();

  /// Menu utama untuk role PRAMUKA
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

  /// Filter menu berdasarkan role user
  static List<MenuItemModel> getMenusForRole(String? role) {
    if (role == null) return [];
    return menus.where((m) => m.isAccessibleBy(role)).toList();
  }
}