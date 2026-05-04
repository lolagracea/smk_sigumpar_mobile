import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/route_names.dart';

class TataUsahaDrawer extends StatelessWidget {
  final String currentRoute;

  const TataUsahaDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF2563EB),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 36,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tata Usaha',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'SMK Negeri 1 Sigumpar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _DrawerItem(
              icon: Icons.home_outlined,
              title: 'Beranda',
              selected: currentRoute == RouteNames.home,
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.home);
              },
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Akademik',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            _DrawerItem(
              icon: Icons.class_outlined,
              title: 'Manajemen Kelas',
              selected: currentRoute == RouteNames.classes,
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.classes);
              },
            ),
            _DrawerItem(
              icon: Icons.groups_outlined,
              title: 'Manajemen Siswa',
              selected: currentRoute == RouteNames.students,
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.students);
              },
            ),
            _DrawerItem(
              icon: Icons.campaign_outlined,
              title: 'Pengumuman',
              selected: currentRoute == RouteNames.announcements,
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.announcements);
              },
            ),
            _DrawerItem(
              icon: Icons.archive_outlined,
              title: 'Arsip Surat',
              selected: currentRoute == RouteNames.letters,
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.letters);
              },
            ),
            _DrawerItem(
              icon: Icons.schedule_outlined,
              title: 'Jadwal Mengajar',
              selected: currentRoute == RouteNames.schedules,
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.schedules);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2563EB) : Colors.grey.shade800;

    return ListTile(
      selected: selected,
      selectedTileColor: const Color(0xFFEFF6FF),
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}