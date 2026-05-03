import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/providers/auth_provider.dart';
import '../../../core/config/scout_menu_config.dart';
import '../../../core/utils/role_helper.dart';
import '../vocational/widgets/pramuka_drawer.dart';
import '../../../core/constants/route_names.dart';

/// ─────────────────────────────────────────────────────────────
/// HomeScreen — Halaman utama setelah login
///
/// PERUBAHAN dari versi lama:
/// - Pakai `user.roles` (List<String>) bukan `user.role` (String)
/// - Drawer muncul berdasarkan multi-role check
/// - Scaffold BENAR: AppBar ada → hamburger muncul otomatis
/// - Tidak ada nested Scaffold
/// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // ✅ MULTI-ROLE: pakai roles (List) bukan role (String)
    final userRoles = user?.roles ?? [];

    debugPrint('🔍 HOME - user: ${user?.name}, roles: $userRoles');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // ✅ WAJIB: AppBar harus ada agar hamburger (☰) muncul
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
        // hamburger (leading) otomatis muncul kalau drawer != null
      ),
      // ✅ WAJIB: drawer harus di root Scaffold (bukan nested)
      drawer: _buildDrawer(context, userRoles),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeCard(user),
            const SizedBox(height: 16),
            _buildRoleBadges(userRoles),
            const SizedBox(height: 16),
            _buildAnnouncementCard(),
          ],
        ),
      ),
    );
  }

  // ── Drawer factory — multi-role check ────────────────────
  Widget? _buildDrawer(BuildContext context, List<String> userRoles) {
    // Tampilkan PramukaDrawer jika user punya akses modul pramuka
    if (ScoutMenuConfig.hasPramukaAccess(userRoles)) {
      return const PramukaDrawer(currentRoute: RouteNames.home);
    }
    // TODO: Tambah drawer untuk role lain di sini saat dikembangkan
    // if (RoleHelper.hasAccess(userRoles, [AppRoles.principal])) {
    //   return const PrincipalDrawer(currentRoute: RouteNames.home);
    // }
    return null;
  }

  // ── Welcome Card ─────────────────────────────────────────
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
          // ✅ Tampilkan primaryRole sebagai label jabatan utama
          Text(
            RoleHelper.getRoleLabel(user?.primaryRole),
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

  // ── Role Badges — tampilkan SEMUA role user ───────────────
  Widget _buildRoleBadges(List<String> userRoles) {
    if (userRoles.isEmpty) return const SizedBox.shrink();

    final bool hasPramuka = ScoutMenuConfig.hasPramukaAccess(userRoles);

    return Column(
      children: [
        // Info modul aktif (pramuka)
        if (hasPramuka)
          Container(
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
          ),

        // Badge semua role (jika lebih dari 1)
        if (userRoles.length > 1) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
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
                Text(
                  'Akses Role (${userRoles.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: userRoles
                      .map(
                        (r) => Chip(
                          label: Text(
                            RoleHelper.getRoleLabel(r),
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor:
                              const Color(0xFF1565C0).withValues(alpha: 0.1),
                          labelStyle:
                              const TextStyle(color: Color(0xFF1565C0)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Announcement Card ────────────────────────────────────
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