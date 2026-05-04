import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/academic/arsip_surat_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';

class ArsipSuratScreen extends StatelessWidget {
  const ArsipSuratScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArsipSuratProvider>();
    final formatter = DateFormat('dd MMM yyyy');

    return ShellScaffold(
      title: 'Arsip Surat',
      body: provider.isLoading
          ? const LoadingWidget()
          : ListView.separated(
        itemCount: provider.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = provider.items[index];

          return Card(
            child: ListTile(
              leading: const Icon(Icons.folder_copy_outlined),
              title: Text(item.perihal),
              subtitle: Text(
                'No: ${item.nomor}\n'
                    'File: ${item.fileName}\n'
                    'Tanggal: ${formatter.format(item.tanggal)}',
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}