import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────
/// MenuItemModel — model untuk item menu di Sidebar/Drawer
///
/// Scalable: allowedRoles memungkinkan filtering per role.
/// Saat ini hanya role 'pramuka' yang digunakan.
/// ─────────────────────────────────────────────────────────
class MenuItemModel {
  final String id;
  final String label;
  final IconData icon;
  final String route;

  /// Daftar role yang boleh melihat menu ini
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

  /// Cek apakah role user boleh mengakses menu ini
  bool isAccessibleBy(String? role) {
    if (role == null) return false;
    return allowedRoles.contains(role);
  }
}