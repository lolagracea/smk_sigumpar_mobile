import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../data/models/schedule_model.dart';
import '../../providers/vice_principal_provider.dart';

class WakilJadwalScreen extends StatelessWidget {
  const WakilJadwalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<VicePrincipalProvider>()..loadJadwal(),
      child: const _WakilJadwalView(),
    );
  }
}

class _WakilJadwalView extends StatefulWidget {
  const _WakilJadwalView();

  @override
  State<_WakilJadwalView> createState() => _WakilJadwalViewState();
}

class _WakilJadwalViewState extends State<_WakilJadwalView> {
  String keyword = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VicePrincipalProvider>();

    final rows = provider.schedules.where((item) {
      final text = [
        item.hari,
        item.mataPelajaran,
        item.namaMapel,
        item.namaKelas,
        item.guruNama,
        item.tingkat,
      ].whereType<String>().join(' ').toLowerCase();

      return text.contains(keyword.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Jadwal'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<VicePrincipalProvider>().loadJadwal(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari hari, guru, kelas, atau mapel...',
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
                    label: 'Total Jadwal',
                    value: provider.schedules.length.toString(),
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
                message: provider.errorMessage ?? 'Gagal memuat jadwal',
              )
            else if (rows.isEmpty)
                const _MessageBox(message: 'Data jadwal tidak ditemukan')
              else
                ...rows.map((item) => _ScheduleCard(item: item)),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleModel item;

  const _ScheduleCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final kelas = item.namaKelas ?? '-';
    final guru = item.guruNama ?? '-';
    final mapel = item.mataPelajaran.isNotEmpty
        ? item.mataPelajaran
        : (item.namaMapel ?? '-');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.schedule),
        ),
        title: Text(
          mapel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$guru\n$kelas • ${item.hari} • ${item.waktuMulai} - ${item.waktuBerakhir}',
        ),
        isThreeLine: true,
      ),
    );
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