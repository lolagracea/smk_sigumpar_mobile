import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/providers/auth_provider.dart';
import '../../../core/utils/role_helper.dart';

/// Hanya tampilkan [child] jika user memiliki salah satu dari [allowedRoles]
class RoleBasedWidget extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleBasedWidget({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, String?>((p) => p.user?.role);
    final allowed = RoleHelper.hasRole(role, allowedRoles);
    if (allowed) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
