import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/perangkat_provider.dart';

class PerangkatScreen extends StatefulWidget {
  const PerangkatScreen({super.key});

  @override
  State<PerangkatScreen> createState() => _PerangkatScreenState();
}

class _PerangkatScreenState extends State<PerangkatScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<PerangkatProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PerangkatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Perangkat Pembelajaran')),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: p.data.length,
        itemBuilder: (_, i) {
          final item = p.data[i];

          return Card(
            child: ListTile(
              title: Text(item['nama'] ?? '-'),
              subtitle: Text(item['status'] ?? '-'),
              trailing: PopupMenuButton<String>(
                onSelected: (val) =>
                    p.review(item['id'], val),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'disetujui', child: Text('Setujui')),
                  PopupMenuItem(value: 'revisi', child: Text('Revisi')),
                  PopupMenuItem(value: 'ditolak', child: Text('Tolak')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}