import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/di/injection_container.dart';
import '../../providers/vice_principal_provider.dart';

class WakilParentingScreen extends StatelessWidget {
  const WakilParentingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<VicePrincipalProvider>()..loadParenting(),
      child: const _WakilParentingView(),
    );
  }
}

class _WakilParentingView extends StatefulWidget {
  const _WakilParentingView();

  @override
  State<_WakilParentingView> createState() => _WakilParentingViewState();
}

class _WakilParentingViewState extends State<_WakilParentingView> {
  String keyword = '';
  String classFilter = 'semua';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VicePrincipalProvider>();

    final rows = provider.parentingNotes.where((item) {
      final text = item.values.join(' ').toLowerCase();
      final matchKeyword = text.contains(keyword.toLowerCase());

      if (classFilter == 'semua') return matchKeyword;

      final kelasId = _read(item, [
        'kelas_id',
        'class_id',
      ]);

      final namaKelas = _read(item, [
        'nama_kelas',
        'kelas',
        'class_name',
      ]);

      return matchKeyword && (kelasId == classFilter || namaKelas == classFilter);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Parenting'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<VicePrincipalProvider>().loadParenting(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari agenda, kelas, atau catatan...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => keyword = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: classFilter,
              decoration: const InputDecoration(
                labelText: 'Filter Kelas',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'semua',
                  child: Text('Semua Kelas'),
                ),
                ...provider.classes.map(
                      (kelas) => DropdownMenuItem(
                    value: kelas.id,
                    child: Text(kelas.namaKelas),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => classFilter = value ?? 'semua');
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total Parenting',
                    value: provider.totalParenting.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Ditampilkan',
                    value: rows.length.toString(),
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
                const _MessageBox(message: 'Data parenting tidak ditemukan')
              else
                ...rows.map((item) => _ParentingCard(item: item)),
          ],
        ),
      ),
    );
  }

  String _read(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }
}

class _ParentingCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ParentingCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final agenda = _read(
      item,
      [
        'agenda',
        'judul',
        'topik',
        'title',
      ],
      fallback: 'Parenting',
    );

    final kelas = _read(
      item,
      [
        'nama_kelas',
        'kelas',
        'class_name',
      ],
      fallback: '-',
    );

    final tanggal = _read(
      item,
      [
        'tanggal',
        'created_at',
        'date',
      ],
      fallback: '-',
    );

    final ringkasan = _read(
      item,
      [
        'ringkasan',
        'catatan',
        'deskripsi',
        'keterangan',
        'summary',
      ],
      fallback: '-',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.family_restroom_outlined),
        ),
        title: Text(
          agenda,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Kelas: $kelas\n$tanggal • $ringkasan'),
        isThreeLine: true,
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
              'Detail Parenting',
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