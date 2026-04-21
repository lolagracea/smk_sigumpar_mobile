import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
                  const SizedBox(height: 8),
                  Text(
                    'Versi mobile ini mengikuti struktur P8, tetapi domain fiturnya disesuaikan dengan basis proyek SMK Negeri 1 Sigumpar.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
