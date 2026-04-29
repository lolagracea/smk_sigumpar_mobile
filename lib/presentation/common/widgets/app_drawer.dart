import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/utils/role_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // Tarik data menu dari fungsi dinamis
    final menus = RoleHelper.getDrawerMenus(user?.role);
    // Kita paksa cetak ke terminal untuk melihat apa isi sebenarnya
    print("===== DEBUGGING =====");
    print("NAMA USER: ${user?.name}");
    print("ROLE USER: '${user?.role}'");
    print("=====================");

// KITA PAKSA APLIKASI MENGANGGAP INI ADALAH TATA USAHA
//     final menus = RoleHelper.getDrawerMenus('tata-usaha');

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              user?.name ?? 'Memuat Profil...',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              RoleHelper.getRoleLabel(user?.role).toUpperCase(),
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: AppColors.primary),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: menus.length,
              itemBuilder: (context, index) {
                final menu = menus[index];

                // CEK: Apakah menu ini memiliki anak (Sub-menu / Dropdown)?
                if (menu.children != null && menu.children!.isNotEmpty) {
                  return ExpansionTile(
                    leading: Icon(menu.icon, color: AppColors.primary),
                    title: Text(
                        menu.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)
                    ),
                    childrenPadding: const EdgeInsets.only(left: 16.0), // Indentasi anak menu
                    // Looping sub-menu di dalam dropdown
                    children: menu.children!.map((child) {
                      return ListTile(
                        leading: Icon(child.icon, color: AppColors.primary, size: 22),
                        title: Text(
                            child.title,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)
                        ),
                        onTap: () {
                          Navigator.pop(context); // Tutup sidebar dulu
                          if (GoRouterState.of(context).uri.toString() != child.route) {
                            context.push(child.route);
                          }
                        },
                      );
                    }).toList(),
                  );
                }

                // JIKA MENU BIASA (Tidak ada dropdown, contohnya: Dashboard)
                return ListTile(
                  leading: Icon(menu.icon, color: AppColors.primary),
                  title: Text(
                      menu.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)
                  ),
                  onTap: () {
                    Navigator.pop(context); // Tutup sidebar
                    if (GoRouterState.of(context).uri.toString() != menu.route) {
                      context.push(menu.route);
                    }
                  },
                );
              },
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Keluar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}