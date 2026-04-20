import 'package:flutter/material.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_scaffold.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: AppEmptyState(
        title: '$title belum dikerjakan',
        subtitle: 'Scaffold halaman sudah dibuat agar integrasi bertahap lebih mudah.',
      ),
    );
  }
}
