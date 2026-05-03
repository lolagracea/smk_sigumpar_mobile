import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../common/providers/auth_provider.dart';
import '../../common/providers/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/utils/role_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user;

    // ✅ FIX: auth.roles (List<String>) — bukan auth.userRoles
    final userRoles = auth.roles;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Avatar & name ───────────────────────────
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),

                      // Badge primary role
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          // ✅ pakai primaryRole (alias .role juga bisa)
                          RoleHelper.getRoleLabel(user.primaryRole),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // ✅ Tampilkan semua role kalau user punya lebih dari 1
                      if (userRoles.length > 1) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: userRoles
                              .where((r) => r != user.primaryRole)
                              .map(
                                (r) => Chip(
                                  label: Text(
                                    RoleHelper.getRoleLabel(r),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor:
                                      AppColors.primaryLight.withOpacity(0.08),
                                  labelStyle: const TextStyle(
                                      color: AppColors.primary),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Info card ──────────────────────────────
                Card(
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.person_outline,
                        label: 'Username',
                        value: user.username,
                      ),
                      const Divider(height: 1, indent: 56),
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                      ),
                      if (user.phone != null) ...[
                        const Divider(height: 1, indent: 56),
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Telepon',
                          value: user.phone!,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Settings card ──────────────────────────
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: const Text('Mode Gelap'),
                        value: themeProvider.isDark,
                        onChanged: (_) => themeProvider.toggleTheme(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Logout ─────────────────────────────────
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text(
                      AppStrings.logout,
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Konfirmasi Keluar'),
                          content:
                              const Text('Apakah Anda yakin ingin keluar?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Keluar',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await context.read<AuthProvider>().logout();
                        context.go(RouteNames.login);
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.grey500),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}