import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/academic/siswa_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';

class SiswaScreen extends StatelessWidget {
  const SiswaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SiswaProvider>();

    return ShellScaffold(
      title: 'Data Siswa',
      body: provider.isLoading
          ? const LoadingWidget()
          : ListView.separated(
              itemCount: provider.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(item.nama),
                    subtitle: Text('NIS: ${item.nis} • Kelas: ${item.kelas}'),
                  ),
                );
              },
            ),
    );
  }
}
