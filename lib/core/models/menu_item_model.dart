import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
/// MenuItemModel — model untuk item menu di Sidebar/Drawer
///
/// Support MULTI-ROLE:
/// - `allowedRoles` adalah list role yang boleh lihat menu ini
/// - `isAccessibleByAny(List<String>)` cek multi-role user
/// - Backward compat: `isAccessibleBy(String?)` tetap ada
/// ─────────────────────────────────────────────────────────────
class MenuItemModel {
  final String id;
  final String label;
  final IconData icon;
  final String route;

  /// Daftar role yang boleh melihat menu ini.
  /// User hanya perlu punya SATU role dari list ini untuk dapat akses.
  final List<String> allowedRoles;

  /// Apakah menu ini adalah header section (pemisah grup)
  final bool isSectionHeader;

  /// Label section header (hanya digunakan jika isSectionHeader = true)
  final String? sectionTitle;

  const MenuItemModel({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    required this.allowedRoles,
    this.isSectionHeader = false,
    this.sectionTitle,
  });

  /// ✅ MULTI-ROLE: Cek apakah user dengan banyak role boleh akses menu ini.
  ///
  /// Returns true kalau ada irisan antara [userRoles] dan [allowedRoles].
  bool isAccessibleByAny(List<String> userRoles) {
    if (userRoles.isEmpty) return false;
    return allowedRoles.any((role) => userRoles.contains(role));
  }

  /// @deprecated Gunakan [isAccessibleByAny] untuk multi-role.
  /// Backward compat: cek akses berdasarkan single role.
  bool isAccessibleBy(String? role) {
    if (role == null) return false;
    return allowedRoles.contains(role);
  }
}