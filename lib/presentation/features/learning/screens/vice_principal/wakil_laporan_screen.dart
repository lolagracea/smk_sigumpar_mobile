import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../core/di/injection_container.dart';
import '../../providers/vice_principal_provider.dart';

class WakilLaporanScreen extends StatelessWidget {
  const WakilLaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<VicePrincipalProvider>()..loadLaporanRingkas(),
      child: const _WakilLaporanView(),
    );
  }
}

class _WakilLaporanView extends StatelessWidget {
  const _WakilLaporanView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VicePrincipalProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Ringkas'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<VicePrincipalProvider>().loadLaporanRingkas(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DateSelector(
              date: provider.selectedDate,
              onChanged: (date) {
                context.read<VicePrincipalProvider>().loadLaporanRingkas(
                  date: date,
                );
              },
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.isError)
              _MessageBox(
                message: provider.errorMessage ?? 'Gagal memuat data',
              )
            else ...[
                const Text(
                  'Ringkasan Monitoring',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _ReportCard(
                      label: 'Total Jadwal',
                      value: provider.totalJadwal.toString(),
                      icon: Icons.schedule_outlined,
                    ),
                    _ReportCard(
                      label: 'Absensi Guru',
                      value: provider.totalAbsensiGuru.toString(),
                      icon: Icons.fact_check_outlined,
                    ),
                    _ReportCard(
                      label: 'Perangkat',
                      value: provider.totalPerangkat.toString(),
                      icon: Icons.folder_copy_outlined,
                    ),
                    _ReportCard(
                      label: 'Parenting',
                      value: provider.totalParenting.toString(),
                      icon: Icons.family_restroom_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Rekap Absensi Guru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Hadir', value: provider.totalHadir.toString()),
                _InfoRow(
                  label: 'Terlambat',
                  value: provider.totalTerlambat.toString(),
                ),
                _InfoRow(label: 'Izin', value: provider.totalIzin.toString()),
                _InfoRow(label: 'Sakit', value: provider.totalSakit.toString()),
                _InfoRow(label: 'Alpa', value: provider.totalAlpa.toString()),
                const SizedBox(height: 20),
                const Text(
                  'Rekap Perangkat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Menunggu Review',
                  value: provider.totalPerangkatMenunggu.toString(),
                ),
                _InfoRow(
                  label: 'Disetujui',
                  value: provider.totalPerangkatDisetujui.toString(),
                ),
                _InfoRow(
                  label: 'Ditolak',
                  value: provider.totalPerangkatDitolak.toString(),
                ),
              ],
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
        title: const Text('Tanggal Laporan'),
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

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReportCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const Spacer(),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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