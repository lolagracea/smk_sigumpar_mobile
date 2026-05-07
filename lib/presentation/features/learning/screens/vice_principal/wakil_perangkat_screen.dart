import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/di/injection_container.dart';
import '../../providers/vice_principal_provider.dart';

class WakilPerangkatScreen extends StatelessWidget {
  const WakilPerangkatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<VicePrincipalProvider>()..loadPerangkat(),
      child: const _WakilPerangkatView(),
    );
  }
}

class _WakilPerangkatView extends StatefulWidget {
  const _WakilPerangkatView();

  @override
  State<_WakilPerangkatView> createState() => _WakilPerangkatViewState();
}

class _WakilPerangkatViewState extends State<_WakilPerangkatView> {
  String keyword = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VicePrincipalProvider>();

    final rows = provider.learningDevices.where((item) {
      final text = item.values.join(' ').toLowerCase();
      return text.contains(keyword.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Perangkat'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<VicePrincipalProvider>().loadPerangkat(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari perangkat, guru, atau status...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => keyword = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total',
                    value: provider.totalPerangkat.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Menunggu',
                    value: provider.totalPerangkatMenunggu.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Disetujui',
                    value: provider.totalPerangkatDisetujui.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Ditolak',
                    value: provider.totalPerangkatDitolak.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.isError)
              _MessageBox(
                message: provider.errorMessage ?? 'Gagal memuat data',
              )
            else if (rows.isEmpty)
                const _MessageBox(message: 'Data perangkat tidak ditemukan')
              else
                ...rows.map((item) => _DeviceCard(item: item)),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _DeviceCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final title = _read(
      item,
      [
        'judul',
        'nama_perangkat',
        'nama_dokumen',
        'nama_file',
        'file_name',
        'jenis_perangkat',
      ],
      fallback: 'Perangkat Pembelajaran',
    );

    final guru = _read(
      item,
      [
        'nama_guru',
        'guru_nama',
        'guru',
        'created_by_name',
      ],
      fallback: '-',
    );

    final jenis = _read(
      item,
      [
        'jenis',
        'jenis_perangkat',
        'tipe',
        'type',
      ],
      fallback: '-',
    );

    final status = _read(
      item,
      [
        'status_wakasek',
        'status_review_wakasek',
        'status',
      ],
      fallback: 'Menunggu',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.folder_copy_outlined),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Guru: $guru\nJenis: $jenis'),
        isThreeLine: true,
        trailing: Chip(
          label: Text(status),
          visualDensity: VisualDensity.compact,
        ),
        onTap: () => _showDetail(context, item),
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Detail Perangkat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...item.entries.map(
                  (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('${entry.key}: ${entry.value ?? '-'}'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _read(
      Map<String, dynamic> item,
      List<String> keys, {
        required String fallback,
      }) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String message;

  const _MessageBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text(message)),
      ),
    );
  }
}