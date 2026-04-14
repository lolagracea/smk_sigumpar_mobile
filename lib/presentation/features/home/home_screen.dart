import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../common/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/utils/role_helper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appShortName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push(RouteNames.profile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Greeting card ───────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang,',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? '-',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    RoleHelper.getRoleLabel(user?.role),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text('Menu Utama',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // ─── Feature grid ────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: _buildMenuItems(context, user?.role),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, String? role) {
    final allMenus = <_MenuItem>[
      _MenuItem(
        title: AppStrings.academic,
        icon: Icons.school_outlined,
        color: AppColors.academic,
        route: RouteNames.classes,
        allowedRoles: [AppRoles.admin, AppRoles.principal, AppRoles.vicePrincipal, AppRoles.staff, AppRoles.teacher, AppRoles.homeroom],
      ),
      _MenuItem(
        title: AppStrings.student,
        icon: Icons.people_outline_rounded,
        color: AppColors.studentService,
        route: RouteNames.attendanceRecap,
        allowedRoles: [AppRoles.admin, AppRoles.principal, AppRoles.homeroom, AppRoles.student],
      ),
      _MenuItem(
        title: AppStrings.learning,
        icon: Icons.menu_book_outlined,
        color: AppColors.learning,
        route: RouteNames.teacherAttendance,
        allowedRoles: [AppRoles.admin, AppRoles.principal, AppRoles.vicePrincipal, AppRoles.teacher, AppRoles.homeroom],
      ),
      _MenuItem(
        title: AppStrings.vocational,
        icon: Icons.engineering_outlined,
        color: AppColors.vocational,
        route: RouteNames.scoutClasses,
        allowedRoles: [AppRoles.admin, AppRoles.principal, AppRoles.teacher, AppRoles.student],
      ),
      _MenuItem(
        title: AppStrings.asset,
        icon: Icons.inventory_2_outlined,
        color: AppColors.assetService,
        route: RouteNames.submissionInfo,
        allowedRoles: [AppRoles.admin, AppRoles.principal, AppRoles.staff, AppRoles.treasurer],
      ),
      _MenuItem(
        title: AppStrings.profile,
        icon: Icons.person_outline_rounded,
        color: AppColors.grey600,
        route: RouteNames.profile,
        allowedRoles: [AppRoles.admin, AppRoles.principal, AppRoles.vicePrincipal, AppRoles.teacher, AppRoles.homeroom, AppRoles.student, AppRoles.staff, AppRoles.treasurer],
      ),
    ];

    return allMenus
        .where((m) => RoleHelper.hasRole(role, m.allowedRoles))
        .map((m) => _MenuCard(item: m))
        .toList();
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final List<String> allowedRoles;

  _MenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    required this.allowedRoles,
  });
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: item.color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
