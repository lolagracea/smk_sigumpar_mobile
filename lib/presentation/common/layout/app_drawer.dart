import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/utils/role_helper.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final items = _getMenuItemsByUser(
      role: user?.role,
      roles: user?.roles,
    );

    return Drawer(
      backgroundColor: const Color(0xFF2563EB),
      child: SafeArea(
        child: Column(
          children: [
            _UserHeader(
              name: user?.name ?? 'Pengguna',
              roleLabel: RoleHelper.getRolesLabel(
                role: user?.role,
                roles: user?.roles,
              ),
            ),
            const Divider(
              color: Colors.white24,
              height: 1,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerMenuItem(
                    icon: Icons.home_filled,
                    label: 'Beranda',
                    route: RouteNames.home,
                    currentRoute: currentRoute,
                  ),
                  const SizedBox(height: 8),
                  ...items.map(
                        (item) => _DrawerMenuItem(
                      icon: item.icon,
                      label: item.label,
                      route: item.route,
                      currentRoute: currentRoute,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              color: Colors.white24,
              height: 1,
            ),
            _LogoutButton(),
          ],
        ),
      ),
    );
  }

  List<_MenuItemData> _getMenuItemsByUser({
    required String? role,
    required List<String>? roles,
  }) {
    final items = <_MenuItemData>[];

    // ─── Tata Usaha / Staff ───────────────────────────────
    // User dengan role utama apa pun tetap mendapat menu ini
    // selama salah satu role-nya adalah tata-usaha.
    if (RoleHelper.hasRole(
      targetRole: AppRoles.staff,
      role: role,
      roles: roles,
    )) {
      items.addAll(const [
        _MenuItemData(
          icon: Icons.class_outlined,
          label: 'Data Kelas',
          route: RouteNames.classes,
        ),
        _MenuItemData(
          icon: Icons.groups_outlined,
          label: 'Data Siswa',
          route: RouteNames.students,
        ),
        _MenuItemData(
          icon: Icons.person_outline,
          label: 'Data Guru',
          route: RouteNames.teachers,
        ),
        _MenuItemData(
          icon: Icons.campaign_outlined,
          label: 'Pengumuman',
          route: RouteNames.announcements,
        ),
        _MenuItemData(
          icon: Icons.archive_outlined,
          label: 'Arsip Surat',
          route: RouteNames.letters,
        ),
        _MenuItemData(
          icon: Icons.schedule_outlined,
          label: 'Jadwal Mengajar',
          route: RouteNames.schedules,
        ),
        _MenuItemData(
          icon: Icons.menu_book_outlined,
          label: 'Mata Pelajaran',
          route: RouteNames.subjects,
        ),
      ]);
    }

    // ─── Guru Mapel ───────────────────────────────────────
    if (RoleHelper.hasRole(
      targetRole: AppRoles.teacher,
      role: role,
      roles: roles,
    )) {
      items.addAll(const [
        _MenuItemData(
          icon: Icons.access_time,
          label: 'Absensi Guru',
          route: RouteNames.teacherAttendance,
        ),
        _MenuItemData(
          icon: Icons.group,
          label: 'Absensi Siswa',
          route: RouteNames.attendanceRecap,
        ),
        _MenuItemData(
          icon: Icons.description_outlined,
          label: 'Perangkat Ajar',
          route: RouteNames.learningDevice,
        ),
        _MenuItemData(
          icon: Icons.bar_chart,
          label: 'Input & Kelola Nilai',
          route: RouteNames.gradesRecap,
        ),
      ]);
    }

    // ─── Wali Kelas ───────────────────────────────────────
    if (RoleHelper.hasRole(
      targetRole: AppRoles.homeroom,
      role: role,
      roles: roles,
    )) {
      items.addAll(const [
        _MenuItemData(
          icon: Icons.how_to_reg_outlined,
          label: 'Presensi Kelas',
          route: RouteNames.attendanceRecap,
        ),
        _MenuItemData(
          icon: Icons.bar_chart_outlined,
          label: 'Rekap Nilai',
          route: RouteNames.gradesRecap,
        ),
        _MenuItemData(
          icon: Icons.family_restroom_outlined,
          label: 'Parenting',
          route: RouteNames.parentingNotes,
        ),
        _MenuItemData(
          icon: Icons.cleaning_services_outlined,
          label: 'Kebersihan Kelas',
          route: RouteNames.cleanlinessRecap,
        ),
        _MenuItemData(
          icon: Icons.edit_note_outlined,
          label: 'Refleksi',
          route: RouteNames.homeroomReflection,
        ),
        _MenuItemData(
          icon: Icons.mail_outline,
          label: 'Surat Panggilan',
          route: RouteNames.summonsLetter,
        ),
      ]);
    }

    // ─── Kepala Sekolah ───────────────────────────────────
    if (RoleHelper.hasRole(
      targetRole: AppRoles.principal,
      role: role,
      roles: roles,
    )) {
      items.addAll(const [
        _MenuItemData(
          icon: Icons.fact_check_outlined,
          label: 'Rekap Absensi Guru',
          route: RouteNames.teacherAttendance,
        ),
        _MenuItemData(
          icon: Icons.groups_outlined,
          label: 'Rekap Absensi Siswa',
          route: RouteNames.attendanceRecap,
        ),
        _MenuItemData(
          icon: Icons.folder_copy_outlined,
          label: 'Pemeriksaan Perangkat',
          route: RouteNames.principalReview,
        ),
        _MenuItemData(
          icon: Icons.assessment_outlined,
          label: 'Evaluasi Kinerja',
          route: RouteNames.teacherEvaluation,
        ),
      ]);
    }

    // ─── Wakil Kepala Sekolah ─────────────────────────────
    if (RoleHelper.hasRole(
      targetRole: AppRoles.vicePrincipal,
      role: role,
      roles: roles,
    )) {
      items.addAll(const [
        _MenuItemData(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard Wakil',
          route: RouteNames.wakilDashboard,
        ),
        _MenuItemData(
          icon: Icons.schedule_outlined,
          label: 'Monitoring Jadwal',
          route: RouteNames.wakilJadwal,
        ),
        _MenuItemData(
          icon: Icons.fact_check_outlined,
          label: 'Absensi Guru',
          route: RouteNames.wakilAbsensiGuru,
        ),
        _MenuItemData(
          icon: Icons.folder_copy_outlined,
          label: 'Perangkat',
          route: RouteNames.wakilPerangkat,
        ),
        _MenuItemData(
          icon: Icons.family_restroom_outlined,
          label: 'Parenting',
          route: RouteNames.wakilParenting,
        ),
        _MenuItemData(
          icon: Icons.assessment_outlined,
          label: 'Laporan Ringkas',
          route: RouteNames.wakilLaporan,
        ),
      ]);
    }

    // ─── Pramuka ──────────────────────────────────────────
    if (RoleHelper.hasRole(
      targetRole: AppRoles.pramuka,
      role: role,
      roles: roles,
    )) {
      items.addAll(const [
        _MenuItemData(
          icon: Icons.groups_2_outlined,
          label: 'Kelas Pramuka',
          route: RouteNames.scoutClasses,
        ),
        _MenuItemData(
          icon: Icons.how_to_reg_outlined,
          label: 'Absensi Pramuka',
          route: RouteNames.scoutAttendance,
        ),
        _MenuItemData(
          icon: Icons.description_outlined,
          label: 'Laporan Pramuka',
          route: RouteNames.scoutReport,
        ),
      ]);
    }

    // ─── Vokasi / PKL ─────────────────────────────────────
    if (RoleHelper.hasRole(
      targetRole: AppRoles.vokasi,
      role: role,
      roles: roles,
    )) {
      items.addAll(const [
        _MenuItemData(
          icon: Icons.location_on_outlined,
          label: 'Lokasi PKL',
          route: RouteNames.pklLocationReport,
        ),
        _MenuItemData(
          icon: Icons.timeline_outlined,
          label: 'Progres PKL',
          route: RouteNames.pklProgressReport,
        ),
      ]);
    }

    // ─── Bendahara ────────────────────────────────────────
    if (RoleHelper.hasRole(
      targetRole: AppRoles.treasurer,
      role: role,
      roles: roles,
    )) {
      items.addAll(const [
        _MenuItemData(
          icon: Icons.inventory_2_outlined,
          label: 'Informasi Pengajuan',
          route: RouteNames.submissionInfo,
        ),
        _MenuItemData(
          icon: Icons.handshake_outlined,
          label: 'Peminjaman Barang',
          route: RouteNames.itemLoan,
        ),
        _MenuItemData(
          icon: Icons.payments_outlined,
          label: 'Respon Bendahara',
          route: RouteNames.treasurerResponse,
        ),
      ]);
    }

    return _removeDuplicateRoutes(items);
  }

  List<_MenuItemData> _removeDuplicateRoutes(List<_MenuItemData> items) {
    final seenRoutes = <String>{};
    final result = <_MenuItemData>[];

    for (final item in items) {
      if (seenRoutes.add(item.route)) {
        result.add(item);
      }
    }

    return result;
  }
}

class _UserHeader extends StatelessWidget {
  final String name;
  final String roleLabel;

  const _UserHeader({
    required this.name,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
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
                  name.toUpperCase(),
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
                  roleLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();

          if (!isActive) {
            context.go(route);
          }
        },
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final router = GoRouter.of(context);
        final authProvider = context.read<AuthProvider>();

        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Konfirmasi Logout'),
              content: const Text('Apakah Anda yakin ingin keluar?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Keluar'),
                ),
              ],
            );
          },
        );

        if (confirm != true) return;

        await authProvider.logout();

        router.go(RouteNames.login);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.logout,
              color: Colors.white,
              size: 20,
            ),
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
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final String route;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.route,
  });
}