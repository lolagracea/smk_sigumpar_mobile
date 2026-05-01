import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../../core/utils/role_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  List<DrawerMenu> _buildMenus(dynamic user) {
    final roles = <String>[
      if (user?.roles != null) ...List<String>.from(user.roles),
      if (user?.role != null && user.role.toString().isNotEmpty)
        user.role.toString(),
    ].toSet().toList();

    return RoleHelper.getMenusForRoles(roles);
  }

  String _getDisplayName(dynamic user) {
    if (user == null) return 'Memuat Profil...';

    final name = user.name?.toString();
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }

    final username = user.username?.toString();
    if (username != null && username.trim().isNotEmpty) {
      return username;
    }

    return 'Pengguna';
  }

  String _getRoleText(dynamic user) {
    if (user == null) return 'USER';

    final roles = <String>[
      if (user.roles != null) ...List<String>.from(user.roles),
      if (user.role != null && user.role.toString().isNotEmpty)
        user.role.toString(),
    ].toSet().toList();

    if (roles.isEmpty) return 'USER';

    if (roles.contains('tata-usaha')) {
      return RoleHelper.getRoleLabel('tata-usaha').toUpperCase();
    }

    return roles.map((role) => RoleHelper.getRoleLabel(role)).join(' • ');
  }

  bool _isCurrentRoute(BuildContext context, String? route) {
    if (route == null || route.isEmpty) return false;

    final current = GoRouterState.of(context).uri.toString();
    return current == route;
  }

  void _goToRoute(BuildContext context, String? route) {
    Navigator.pop(context);

    if (route == null || route.isEmpty) return;

    if (!_isCurrentRoute(context, route)) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final menus = _buildMenus(user);

    debugPrint('===== DEBUGGING DRAWER =====');
    debugPrint('NAMA USER: ${_getDisplayName(user)}');
    debugPrint('ROLE UTAMA: ${user?.role}');
    debugPrint('SEMUA ROLE: ${user?.roles}');
    debugPrint('JUMLAH MENU: ${menus.length}');
    debugPrint('============================');

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              _getDisplayName(user),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              _getRoleText(user).toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),

          Expanded(
            child: menus.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tidak ada menu untuk role ini',
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: menus.length,
              itemBuilder: (context, index) {
                final menu = menus[index];

                if (menu.children != null &&
                    menu.children!.isNotEmpty) {
                  return ExpansionTile(
                    leading: Icon(
                      menu.icon,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      menu.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    initiallyExpanded: menu.title == 'Manajemen Akademik',
                    childrenPadding: const EdgeInsets.only(left: 16),
                    children: menu.children!.map((child) {
                      return ListTile(
                        leading: Icon(
                          child.icon,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        title: Text(
                          child.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        selected: _isCurrentRoute(context, child.route),
                        onTap: () => _goToRoute(context, child.route),
                      );
                    }).toList(),
                  );
                }

                return ListTile(
                  leading: Icon(
                    menu.icon,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    menu.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: _isCurrentRoute(context, menu.route),
                  onTap: () => _goToRoute(context, menu.route),
                );
              },
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
            ),
            title: const Text(
              'Keluar',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
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