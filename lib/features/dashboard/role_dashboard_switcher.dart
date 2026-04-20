import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleDashboardSwitcher extends StatelessWidget {
  const RoleDashboardSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final menus = <({String title, String route, IconData icon})>[
      (title: 'Kelas', route: '/tata-usaha/kelas', icon: Icons.class_),
      (title: 'Siswa', route: '/tata-usaha/siswa', icon: Icons.people_alt_outlined),
      (title: 'Pengumuman', route: '/tata-usaha/pengumuman', icon: Icons.campaign_outlined),
      (title: 'Arsip Surat', route: '/tata-usaha/arsip-surat', icon: Icons.folder_copy_outlined),
      (title: 'Wali Kelas', route: '/coming-soon/wali-kelas', icon: Icons.school_outlined),
      (title: 'Guru Mapel', route: '/coming-soon/guru-mapel', icon: Icons.menu_book_outlined),
      (title: 'Aset', route: '/coming-soon/aset', icon: Icons.inventory_2_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: menus.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final item = menus[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go(item.route),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
