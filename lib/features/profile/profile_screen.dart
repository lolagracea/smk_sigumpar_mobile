import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../shared/shell_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final roles = (user?.roles ?? <String>[]).join(', ');

    return ShellScaffold(
      title: 'Profil',
      body: Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(user?.name ?? '-'),
          subtitle: Text(
            'Username: ${user?.username ?? '-'}\n'
                'Role: $roles',
          ),
        ),
      ),
    );
  }
}