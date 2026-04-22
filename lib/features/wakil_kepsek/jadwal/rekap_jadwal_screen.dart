import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/wakil_kepsek_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning/wakil_jadwal_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';

class RekapJadwalScreen extends StatefulWidget {
  const RekapJadwalScreen({super.key});

  @override
  State<RekapJadwalScreen> createState() => _RekapJadwalScreenState();
}

class _RekapJadwalScreenState extends State<RekapJadwalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final token = context.read<AuthProvider>().currentUser?.token ?? '';
    context.read<WakilJadwalProvider>().loadRekapHari(token);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WakilJadwalProvider>();

    return ShellScaffold(
      title: 'Rekap Jadwal per Hari',
      body: prov.isLoadingRekap
          ? const LoadingWidget()
          : prov.errorRekap != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(prov.errorRekap!),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              : prov.rekapHari.isEmpty
                  ? const Center(child: Text('Tidak ada data rekap'))
                  : RefreshIndicator(
                      onRefresh: () async => _load(),
                      child: ListView(
                        children: <Widget>[
                          // ── Ringkasan total ──────────────────────────
                          _TotalSummaryCard(list: prov.rekapHari),
                          const SizedBox(height: 16),
                          const Text(
                            'Rincian per Hari',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 10),
                          ...prov.rekapHari
                              .map((r) => _RekapHariCard(rekap: r)),
                        ],
                      ),
                    ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────
class _TotalSummaryCard extends StatelessWidget {
  const _TotalSummaryCard({required this.list});
  final List<RekapHariModel> list;

  @override
  Widget build(BuildContext context) {
    final totalJam = list.fold(0, (s, r) => s + r.totalJam);
    final maxGuru = list.isEmpty ? 0 : list.map((r) => r.totalGuru).reduce((a, b) => a > b ? a : b);
    final hariAktif = list.length;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _SummaryItem(
                value: '$totalJam', label: 'Total Jam', icon: Icons.schedule),
            _SummaryItem(
                value: '$hariAktif', label: 'Hari Aktif', icon: Icons.today),
            _SummaryItem(
                value: '$maxGuru',
                label: 'Maks Guru/Hari',
                icon: Icons.people_outline),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem(
      {required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ─── Rekap Hari Card ──────────────────────────────────────────────────────────
class _RekapHariCard extends StatelessWidget {
  const _RekapHariCard({required this.rekap});
  final RekapHariModel rekap;

  static const Map<String, Color> _hariColors = <String, Color>{
    'Senin': Colors.blue,
    'Selasa': Colors.green,
    'Rabu': Colors.orange,
    'Kamis': Colors.purple,
    'Jumat': Colors.teal,
    'Sabtu': Colors.pink,
  };

  @override
  Widget build(BuildContext context) {
    final color = _hariColors[rekap.hari] ?? Colors.blueGrey;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                rekap.hari.substring(0, 3),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    rekap.hari,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      _InfoBadge(
                          label: '${rekap.totalJam} Jam',
                          color: Colors.blue),
                      const SizedBox(width: 6),
                      _InfoBadge(
                          label: '${rekap.totalGuru} Guru',
                          color: Colors.green),
                      const SizedBox(width: 6),
                      _InfoBadge(
                          label: '${rekap.totalKelas} Kelas',
                          color: Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}
