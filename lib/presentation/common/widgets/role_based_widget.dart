import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/role_helper.dart';
import '../providers/auth_provider.dart';

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
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final canAccess = RoleHelper.hasAnyRole(
      targetRoles: allowedRoles,
      role: user?.role,
      roles: user?.roles,
    );

    if (canAccess) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

class RoleBasedBuilder extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget Function(BuildContext context) builder;
  final Widget Function(BuildContext context)? fallbackBuilder;

  const RoleBasedBuilder({
    super.key,
    required this.allowedRoles,
    required this.builder,
    this.fallbackBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final canAccess = RoleHelper.hasAnyRole(
      targetRoles: allowedRoles,
      role: user?.role,
      roles: user?.roles,
    );

    if (canAccess) {
      return builder(context);
    }

    if (fallbackBuilder != null) {
      return fallbackBuilder!(context);
    }

    return const SizedBox.shrink();
  }
}

class HideForRoles extends StatelessWidget {
  final List<String> hiddenRoles;
  final Widget child;
  final Widget? fallback;

  const HideForRoles({
    super.key,
    required this.hiddenRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final shouldHide = RoleHelper.hasAnyRole(
      targetRoles: hiddenRoles,
      role: user?.role,
      roles: user?.roles,
    );

    if (shouldHide) {
      return fallback ?? const SizedBox.shrink();
    }

    return child;
  }
}
