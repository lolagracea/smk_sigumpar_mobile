import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../data/models/absensi_guru_model.dart';
import '../../providers/vice_principal_provider.dart';

class WakilAbsensiGuruScreen extends StatelessWidget {
  const WakilAbsensiGuruScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<VicePrincipalProvider>()..loadAbsensiGuru(),
      child: const _WakilAbsensiGuruView(),
    );
  }
}

class _WakilAbsensiGuruView extends StatefulWidget {
  const _WakilAbsensiGuruView();

  @override
  State<_WakilAbsensiGuruView> createState() => _WakilAbsensiGuruViewState();
}

class _WakilAbsensiGuruViewState extends State<_WakilAbsensiGuruView> {
  String keyword = '';
  String statusFilter = 'semua';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VicePrincipalProvider>();

    final rows = provider.teacherAttendances.where((item) {
      final text = [
        item.namaGuru,
        item.mataPelajaran,
        item.status.label,
        item.keterangan,
      ].whereType<String>().join(' ').toLowerCase();

      final matchKeyword = text.contains(keyword.toLowerCase());
      final matchStatus =
          statusFilter == 'semua' || item.status.value == statusFilter;

      return matchKeyword && matchStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Absensi Guru'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<VicePrincipalProvider>().loadAbsensiGuru(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DateSelector(
              date: provider.selectedDate,
              onChanged: (date) {
                context.read<VicePrincipalProvider>().loadAbsensiGuru(
                  date: date,
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari guru, mapel, atau status...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => keyword = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: statusFilter,
              decoration: const InputDecoration(
                labelText: 'Filter Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'semua', child: Text('Semua')),
                DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                DropdownMenuItem(value: 'izin', child: Text('Izin')),
                DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                DropdownMenuItem(value: 'alpa', child: Text('Alpa')),
              ],
              onChanged: (value) {
                setState(() => statusFilter = value ?? 'semua');
              },
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _MiniStat(label: 'Total', value: rows.length.toString()),
                _MiniStat(
                  label: 'Hadir',
                  value: provider.totalHadir.toString(),
                ),
                _MiniStat(
                  label: 'Terlambat',
                  value: provider.totalTerlambat.toString(),
                ),
                _MiniStat(
                  label: 'Alpa',
                  value: provider.totalAlpa.toString(),
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
                const _MessageBox(message: 'Data absensi guru tidak ditemukan')
              else
                ...rows.map((item) => _AttendanceCard(item: item)),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DateSelector({
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month_outlined),
        title: const Text('Tanggal Monitoring'),
        subtitle: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final selected = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );

          if (selected != null) {
            onChanged(selected);
          }
        },
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AbsensiGuruModel item;

  const _AttendanceCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final tanggal = DateFormat('dd MMM yyyy', 'id_ID').format(item.tanggal);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(item.namaGuru.isNotEmpty ? item.namaGuru[0] : '?'),
        ),
        title: Text(
          item.namaGuru,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${item.mataPelajaran}\n$tanggal • ${item.jamMasuk ?? '-'} • ${item.keterangan ?? '-'}',
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(item.status.label),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
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