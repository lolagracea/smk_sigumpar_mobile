import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../common/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/role_helper.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const MainShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 800,
            selectedIndex: _getSelectedIndex(currentRoute),
            onDestinationSelected: (index) => _navigateToIndex(context, index),
            leading: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.school_rounded,
                    size: 32, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  AppStrings.appShortName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 16),
                const Divider(),
              ],
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          (user?.name ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        RoleHelper.getRoleLabel(user?.role),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: _buildDestinations(context, user?.role),
            labelType: NavigationRailLabelType.none,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  List<NavigationRailDestination> _buildDestinations(
      BuildContext context, String? role) {
    final destinations = <_NavigationItem>[
      _NavigationItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Beranda',
        route: '/home',
        roles: _allRoles,
      ),
      _NavigationItem(
        icon: Icons.school_outlined,
        selectedIcon: Icons.school_rounded,
        label: 'Akademik',
        route: '/academic/classes',
        roles: [
          AppRoles.admin,
          AppRoles.principal,
          AppRoles.vicePrincipal,
          AppRoles.staff,
          AppRoles.teacher,
          AppRoles.homeroom,
        ],
      ),
      _NavigationItem(
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_rounded,
        label: 'Siswa',
        route: '/student/attendance',
        roles: [
          AppRoles.admin,
          AppRoles.principal,
          AppRoles.homeroom,
          AppRoles.student,
        ],
      ),
      _NavigationItem(
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book_rounded,
        label: 'Pembelajaran',
        route: '/learning/teacher-attendance',
        roles: [
          AppRoles.admin,
          AppRoles.principal,
          AppRoles.vicePrincipal,
          AppRoles.teacher,
          AppRoles.homeroom,
        ],
      ),
      _NavigationItem(
        icon: Icons.engineering_outlined,
        selectedIcon: Icons.engineering_rounded,
        label: 'Vokasi',
        route: '/vocational/scout-classes',
        roles: [
          AppRoles.admin,
          AppRoles.principal,
          AppRoles.teacher,
          AppRoles.student,
        ],
      ),
      _NavigationItem(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2_rounded,
        label: 'Aset',
        route: '/asset/submissions',
        roles: [
          AppRoles.admin,
          AppRoles.principal,
          AppRoles.staff,
          AppRoles.treasurer,
        ],
      ),
    ];

    return destinations
        .where((d) => RoleHelper.hasAnyRole(
              targetRoles: d.roles,
              role: role,
            ))
        .map(
          (d) => NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
        )
        .toList();
  }

  int _getSelectedIndex(String route) {
    if (route == '/home') return 0;
    if (route.startsWith('/academic')) return 1;
    if (route.startsWith('/student')) return 2;
    if (route.startsWith('/learning')) return 3;
    if (route.startsWith('/vocational')) return 4;
    if (route.startsWith('/asset')) return 5;
    return 0;
  }

  void _navigateToIndex(BuildContext context, int index) {
    final routes = [
      '/home',
      '/academic/classes',
      '/student/attendance',
      '/learning/teacher-attendance',
      '/vocational/scout-classes',
      '/asset/submissions',
    ];
    if (index < routes.length) {
      context.go(routes[index]);
    }
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final List<String> roles;

  _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    required this.roles,
  });
}

const List<String> _allRoles = [
  AppRoles.admin,
  AppRoles.principal,
  AppRoles.vicePrincipal,
  AppRoles.teacher,
  AppRoles.homeroom,
  AppRoles.student,
  AppRoles.staff,
  AppRoles.pramuka,
  AppRoles.vokasi,
  AppRoles.treasurer,
];
