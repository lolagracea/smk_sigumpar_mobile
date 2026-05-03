import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/scout_menu_config.dart';
import '../../../../core/models/menu_item_model.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../../core/constants/route_names.dart';
import '../../../common/providers/auth_provider.dart';

class PramukaDrawer extends StatelessWidget {
  final String currentRoute;

  const PramukaDrawer({
    super.key,
    required this.currentRoute,
  });

  static const _primaryBlue = Color(0xFF1565C0);
  static const _white = Colors.white;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final menus = ScoutMenuConfig.getMenusForRole(user?.role);

    return Drawer(
      backgroundColor: _primaryBlue,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(user?.name ?? 'Pembina Pramuka'),
            const Divider(color: Colors.white24, height: 1, thickness: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: menus.length,
                itemBuilder: (context, index) {
                  final menu = menus[index];
                  return _buildMenuItem(
                    context: context,
                    menu: menu,
                    isActive: currentRoute == menu.route,
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24, height: 1, thickness: 1),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_activity_rounded,
                  color: Colors.amber,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'PEMBINA PRAMUKA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: _primaryBlue,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: _white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            RoleHelper.getRoleLabel(AppRoles.pramuka),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required MenuItemModel menu,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive ? Border.all(color: Colors.white24, width: 1) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            menu.icon,
            color: isActive ? Colors.white : Colors.white70,
            size: 20,
          ),
        ),
        title: Text(
          menu.label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: isActive
            ? Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        dense: true,
        onTap: () {
          Navigator.of(context).pop();
          if (currentRoute != menu.route) {
            context.go(menu.route);
          }
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showLogoutDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Konfirmasi Logout'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}