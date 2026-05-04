import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/academic/kelas_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';

class KelasScreen extends StatelessWidget {
  const KelasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KelasProvider>();

    return ShellScaffold(
      title: 'Data Kelas',
      body: provider.isLoading
          ? const LoadingWidget()
          : ListView.separated(
              itemCount: provider.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.class_outlined),
                    title: Text(item.nama),
                    subtitle: Text('Tingkat ${item.tingkat} • Wali: ${item.waliKelas}'),
                  ),
                );
              },
            ),
    );
  }
}
