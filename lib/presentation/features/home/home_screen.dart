import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/providers/auth_provider.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/utils/role_helper.dart';
import '../vocational/widgets/pramuka_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final role = user?.role;

    // ✅ DEBUG ROLE
    debugPrint('🔍 HOME - user: ${user?.name}, role: "$role"');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: _buildDrawerByRole(context, role),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 24),
            SizedBox(width: 8),
            Text(
              'SMK NEGERI 1 SIGUMPAR',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeCard(user),
            const SizedBox(height: 16),
            _buildRoleBadge(role),
            const SizedBox(height: 16),
            _buildAnnouncementCard(),
          ],
        ),
      ),
    );
  }

  // ── Drawer factory — hanya PRAMUKA aktif ────────────
  Widget? _buildDrawerByRole(BuildContext context, String? role) {
    if (role == AppRoles.pramuka) {
      return const PramukaDrawer(currentRoute: RouteNames.home);
    }
    return null;
  }

  // ── Welcome Card ─────────────────────────────────────
  Widget _buildWelcomeCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat Datang',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.name ?? 'Loading...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            RoleHelper.getRoleLabel(user?.role),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sistem informasi sekolah untuk mengelola data akademik '
            'dan administrasi pendidikan dengan mudah dan efisien.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Role Badge — hanya PRAMUKA ───────────────────────
  Widget _buildRoleBadge(String? role) {
    if (role != AppRoles.pramuka) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_activity_rounded,
              color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Modul Aktif: PRAMUKA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                'Gunakan menu ☰ untuk navigasi fitur',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Announcement Card ────────────────────────────────
  Widget _buildAnnouncementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengumuman Terbaru',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.grey.shade400,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada pengumuman terbaru',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}