import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/utils/role_helper.dart';
import '../providers/auth_provider.dart';

class UserAccountMenu extends StatelessWidget {
  const UserAccountMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return PopupMenuButton<String>(
      tooltip: 'Akun',
      offset: const Offset(0, 48),
      icon: CircleAvatar(
        radius: 17,
        backgroundColor: Colors.white,
        child: Text(
          _getInitial(user?.name),
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onSelected: (value) async {
        if (value == 'profile') {
          context.go(RouteNames.profile);
          return;
        }

        if (value == 'logout') {
          await _confirmLogout(context);
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Pengguna',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  RoleHelper.getRoleLabel(user?.role),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline),
                SizedBox(width: 10),
                Text('Profil'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                SizedBox(width: 10),
                Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  String _getInitial(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';

    return name.trim().substring(0, 1).toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context) async {
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

    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (context.mounted) {
      context.go(RouteNames.login);
    }
  }
}