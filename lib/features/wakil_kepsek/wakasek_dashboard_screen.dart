import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../shared/shell_scaffold.dart';
import '../../shared/widgets/menu_card.dart';

class WakasekDashboardScreen extends StatelessWidget {
  const WakasekDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ShellScaffold(
      title: 'Wakil Kepala Sekolah',
      actions: <Widget>[
        IconButton(
          onPressed: context.read<ThemeProvider>().toggleTheme,
          icon: const Icon(Icons.brightness_6_outlined),
        ),
        IconButton(
          onPressed: () {
            context.read<AuthProvider>().logout();
            context.go('/login');
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: ListView(
        children: <Widget>[
          // ─── Welcome card ──────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Halo, ${auth.currentUser?.name ?? 'Wakasek'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Wakil Kepala Sekolah',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ─── Menu cards ───────────────────────────────────
          MenuCard(
            title: 'Perangkat Pembelajaran',
            subtitle: 'Review & setujui dokumen perangkat guru',
            icon: Icons.description_outlined,
            onTap: () => context.push('/wakasek/perangkat'),
          ),
          MenuCard(
            title: 'Evaluasi Guru',
            subtitle: 'Buat dan lihat evaluasi kinerja guru',
            icon: Icons.star_outline,
            onTap: () => context.push('/wakasek/evaluasi-guru'),
          ),
          MenuCard(
            title: 'Catatan Mengajar',
            subtitle: 'Monitor catatan mengajar guru',
            icon: Icons.book_outlined,
            onTap: () => context.push('/wakasek/catatan-mengajar'),
          ),
          MenuCard(
            title: 'Profil',
            subtitle: 'Lihat profil akun',
            icon: Icons.person_outline,
            onTap: () => context.push('/profile'),
          ),
        ],
      ),
    );
  }
}