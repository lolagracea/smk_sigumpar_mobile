import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../common/providers/auth_provider.dart';
import '../../../../core/constants/route_names.dart';

class GuruMapelDrawer extends StatelessWidget {
  /// Route yang sedang aktif (untuk highlight menu)
  final String currentRoute;

  const GuruMapelDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Drawer(
      backgroundColor: const Color(0xFF2563EB), // Biru sesuai mockup
      child: SafeArea(
        child: Column(
          children: [
            // ─── HEADER USER PROFILE ──────────────────────
            _buildUserHeader(
              name: user?.name.toUpperCase() ?? 'GURU MAPEL',
              role: 'Guru Mata Pelajaran',
            ),

            const Divider(color: Colors.white24, height: 1),

            // ─── MENU ITEMS ───────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.home_filled,
                    label: 'Beranda',
                    route: RouteNames.home,
                    isActive: currentRoute == RouteNames.home,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.access_time,
                    label: 'Absensi Guru',
                    route: RouteNames.absensiGuru,
                    isActive: currentRoute == RouteNames.absensiGuru,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.group,
                    label: 'Absensi Siswa',
                    route: RouteNames.studentAttendance,
                    isActive: currentRoute == RouteNames.studentAttendance,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.description,
                    label: 'Perangkat Ajar',
                    route: RouteNames.learningDevice,
                    isActive: currentRoute == RouteNames.learningDevice,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.bar_chart,
                    label: 'Input & Kelola Nilai',
                    route: RouteNames.gradesRecap,
                    isActive: currentRoute == RouteNames.gradesRecap,
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white24, height: 1),

            // ─── LOGOUT BUTTON ────────────────────────────
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  // ─── User Header Widget ─────────────────────────────────
  Widget _buildUserHeader({
    required String name,
    required String role,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF2563EB),
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Menu Item Widget ───────────────────────────────────
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        dense: true,
        onTap: () {
          // Tutup drawer dulu
          Navigator.of(context).pop();

          // Navigate kalau route berbeda
          if (currentRoute != route) {
            context.go(route);
          }
        },
      ),
    );
  }

  // ─── Logout Button ──────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                'KELUAR',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Logout Dialog ──────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Tutup dialog

              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();

              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}