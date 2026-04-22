import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/wakil_kepsek_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning/wakil_laporan_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';

class LaporanRingkasScreen extends StatefulWidget {
  const LaporanRingkasScreen({super.key});

  @override
  State<LaporanRingkasScreen> createState() => _LaporanRingkasScreenState();
}

class _LaporanRingkasScreenState extends State<LaporanRingkasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final token = context.read<AuthProvider>().currentUser?.token ?? '';
    context.read<WakilLaporanProvider>().loadLaporan(token);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WakilLaporanProvider>();

    return ShellScaffold(
      title: 'Laporan Ringkas',
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _load,
        ),
      ],
      body: prov.isLoading
          ? const LoadingWidget()
          : prov.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.error_outline,
                          size: 48,
                          color:
                              Theme.of(context).colorScheme.error),
                      const SizedBox(height: 12),
                      Text(prov.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              : prov.laporan == null
                  ? const Center(child: Text('Tidak ada data'))
                  : RefreshIndicator(
                      onRefresh: () async => _load(),
                      child: _LaporanBody(laporan: prov.laporan!),
                    ),
    );
  }
}

class _LaporanBody extends StatelessWidget {
  const _LaporanBody({required this.laporan});
  final LaporanRingkasModel laporan;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        // ── Perangkat Progress ─────────────────────────────────────────
        _SectionCard(
          title: 'Perangkat Pembelajaran',
          icon: Icons.assignment_outlined,
          color: Colors.indigo,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _StatColumn(
                      value: '${laporan.totalPerangkat}',
                      label: 'Total'),
                  _StatColumn(
                      value: '${laporan.perangkatLengkap}',
                      label: 'Lengkap',
                      valueColor: Colors.green),
                  _StatColumn(
                      value: '${laporan.perangkatBelumLengkap}',
                      label: 'Belum',
                      valueColor: Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: laporan.persentasePerangkat,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          laporan.persentasePerangkat >= 0.8
                              ? Colors.green
                              : laporan.persentasePerangkat >= 0.5
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(laporan.persentasePerangkat * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Guru & Kelas ───────────────────────────────────────────────
        _SectionCard(
          title: 'Guru & Kelas',
          icon: Icons.school_outlined,
          color: Colors.teal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _StatColumn(
                  value: '${laporan.totalGuru}', label: 'Guru'),
              _StatColumn(
                  value: '${laporan.totalKelas}', label: 'Kelas'),
            ],
          ),
        ),

        // ── Jadwal ────────────────────────────────────────────────────
        _SectionCard(
          title: 'Jadwal Mengajar',
          icon: Icons.calendar_today_outlined,
          color: Colors.blue,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _StatColumn(
                  value: '${laporan.totalJamJadwal}', label: 'Total Jam'),
              _StatColumn(
                  value: '${laporan.totalGuruJadwal}',
                  label: 'Guru Terjadwal'),
              _StatColumn(
                  value: '${laporan.totalKelasJadwal}',
                  label: 'Kelas Terjadwal'),
            ],
          ),
        ),

        // ── Parenting ─────────────────────────────────────────────────
        _SectionCard(
          title: 'Parenting Log',
          icon: Icons.family_restroom_outlined,
          color: Colors.pink,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _StatColumn(
                  value: '${laporan.totalParenting}',
                  label: 'Total Catatan'),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Text(
          'Data diambil dari learning-service\nSMK Negeri 1 Sigumpar',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Stat Column ─────────────────────────────────────────────────────────────
class _StatColumn extends StatelessWidget {
  const _StatColumn(
      {required this.value, required this.label, this.valueColor});
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: valueColor),
        ),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
