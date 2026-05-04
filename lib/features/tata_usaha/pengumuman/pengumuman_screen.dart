import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/academic/pengumuman_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';

class PengumumanScreen extends StatelessWidget {
  const PengumumanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PengumumanProvider>();
    final formatter = DateFormat('dd MMM yyyy');

    return ShellScaffold(
      title: 'Pengumuman',
      body: provider.isLoading
          ? const LoadingWidget()
          : ListView.separated(
        itemCount: provider.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = provider.items[index];

          return Card(
            child: ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: Text(item.judul),
              subtitle: Text(
                '${item.isi}\n${formatter.format(item.tanggal)}',
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}