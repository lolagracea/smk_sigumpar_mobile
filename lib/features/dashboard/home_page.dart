import 'package:flutter/material.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_card.dart';
import 'role_dashboard_switcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Beranda',
      body: ListView(
        children: const [
          AppSectionCard(
            title: 'Dashboard Peran',
            child: SizedBox(
              height: 340,
              child: RoleDashboardSwitcher(),
            ),
          ),
        ],
      ),
    );
  }
}
