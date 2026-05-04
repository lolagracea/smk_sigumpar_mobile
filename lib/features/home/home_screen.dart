import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/role_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../shared/shell_scaffold.dart';
import '../../shared/widgets/menu_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final roles = authProvider.currentUser?.roles ?? <String>[];

    final bool isTataUsaha = roles.contains(RoleConstants.tataUsaha);
    final bool isWakasek = roles.contains(RoleConstants.wakaSekolah);
    final bool isAdmin = roles.contains(RoleConstants.admin);

    return ShellScaffold(
      title: 'Beranda',
      actions: <Widget>[
        IconButton(
          onPressed: context.read<ThemeProvider>().toggleTheme,
          icon: const Icon(Icons.brightness_6_outlined),
        ),
        IconButton(
          onPressed: () {
            context.read<AuthProvider>().logout();
            context.go(RouteConstants.login);
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: ListView(
        children: <Widget>[
          // ─── Welcome card ────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Selamat datang, ${authProvider.currentUser?.name ?? 'User'}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SMK Negeri 1 Sigumpar',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ─── Menu Tata Usaha ──────────────────────────────
          if (isTataUsaha || isAdmin) ...<Widget>[
            _SectionLabel(label: 'Tata Usaha'),
            MenuCard(
              title: 'Kelas',
              subtitle: 'Manajemen data kelas',
              icon: Icons.class_outlined,
              onTap: () => context.push(RouteConstants.kelas),
            ),
            MenuCard(
              title: 'Siswa',
              subtitle: 'Manajemen data siswa',
              icon: Icons.groups_outlined,
              onTap: () => context.push(RouteConstants.siswa),
            ),
            MenuCard(
              title: 'Pengumuman',
              subtitle: 'Informasi dan pengumuman sekolah',
              icon: Icons.campaign_outlined,
              onTap: () => context.push(RouteConstants.pengumuman),
            ),
            MenuCard(
              title: 'Arsip Surat',
              subtitle: 'Dokumen surat sekolah',
              icon: Icons.folder_copy_outlined,
              onTap: () => context.push(RouteConstants.arsipSurat),
            ),
            const SizedBox(height: 8),
          ],

          // ─── Menu Wakil Kepala Sekolah ────────────────────
          if (isWakasek || isAdmin) ...<Widget>[
            _SectionLabel(label: 'Wakil Kepala Sekolah'),
            MenuCard(
              title: 'Perangkat Pembelajaran',
              subtitle: 'Review & setujui dokumen perangkat guru',
              icon: Icons.description_outlined,
              onTap: () => context.push(RouteConstants.wakasekPerangkat),
            ),
            MenuCard(
              title: 'Evaluasi Guru',
              subtitle: 'Buat dan lihat evaluasi kinerja guru',
              icon: Icons.star_outline,
              onTap: () => context.push(RouteConstants.wakasekEvaluasiGuru),
            ),
            MenuCard(
              title: 'Catatan Mengajar',
              subtitle: 'Monitor catatan mengajar guru',
              icon: Icons.book_outlined,
              onTap: () =>
                  context.push(RouteConstants.wakasekCatatanMengajar),
            ),
            const SizedBox(height: 8),
          ],

          // ─── Jika belum ada role dikenali ─────────────────
          if (!isTataUsaha && !isWakasek && !isAdmin)
            MenuCard(
              title: 'Tidak ada menu tersedia',
              subtitle: 'Hubungi administrator untuk akses',
              icon: Icons.lock_outline,
              onTap: () {},
            ),

          // ─── Profil selalu muncul ─────────────────────────
          MenuCard(
            title: 'Profil',
            subtitle: 'Lihat profil akun',
            icon: Icons.person_outline,
            onTap: () => context.push(RouteConstants.profile),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4, top: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
