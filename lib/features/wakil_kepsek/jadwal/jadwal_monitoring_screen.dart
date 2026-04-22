import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/wakil_kepsek_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning/wakil_jadwal_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';

class JadwalMonitoringScreen extends StatefulWidget {
  const JadwalMonitoringScreen({super.key});

  @override
  State<JadwalMonitoringScreen> createState() =>
      _JadwalMonitoringScreenState();
}

class _JadwalMonitoringScreenState extends State<JadwalMonitoringScreen> {
  static const List<String> _hariOptions = <String>[
    'Semua',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  String _selectedHari = 'Semua';
  final TextEditingController _mapelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _mapelCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final token = context.read<AuthProvider>().currentUser?.token ?? '';
    final prov = context.read<WakilJadwalProvider>();
    prov.setFilter(
      hari: _selectedHari == 'Semua' ? null : _selectedHari,
      mapel: _mapelCtrl.text.trim().isEmpty ? null : _mapelCtrl.text.trim(),
    );
    prov.loadJadwal(token);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WakilJadwalProvider>();

    return ShellScaffold(
      title: 'Monitoring Jadwal',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Filter Bar ────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  // Filter Hari
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _hariOptions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 6),
                      itemBuilder: (_, idx) {
                        final hari = _hariOptions[idx];
                        final active = _selectedHari == hari;
                        return FilterChip(
                          label: Text(hari),
                          selected: active,
                          onSelected: (_) {
                            setState(() => _selectedHari = hari);
                            _load();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Filter Mapel
                  TextField(
                    controller: _mapelCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari mata pelajaran...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      suffixIcon: _mapelCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _mapelCtrl.clear();
                                _load();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ],
              ),
            ),
          ),

          // ── Bentrok Banner ─────────────────────────────────────────────
          if (!prov.isLoading && prov.totalBentrok > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${prov.totalBentrok} jadwal terdeteksi bentrok!',
                      style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // ── Jumlah hasil ───────────────────────────────────────────────
          if (!prov.isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${prov.jadwalList.length} jadwal ditemukan',
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

          // ── Konten ────────────────────────────────────────────────────
          Expanded(
            child: prov.isLoading
                ? const LoadingWidget()
                : prov.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(prov.error!),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      )
                    : prov.jadwalList.isEmpty
                        ? const Center(child: Text('Tidak ada jadwal'))
                        : RefreshIndicator(
                            onRefresh: () async => _load(),
                            child: ListView.separated(
                              itemCount: prov.jadwalList.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) =>
                                  _JadwalTile(
                                      jadwal: prov.jadwalList[idx]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Jadwal Tile ──────────────────────────────────────────────────────────────
class _JadwalTile extends StatelessWidget {
  const _JadwalTile({required this.jadwal});
  final JadwalModel jadwal;

  @override
  Widget build(BuildContext context) {
    final borderColor = jadwal.isBentrok ? Colors.red : Colors.transparent;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            // Kolom hari + jam
            Container(
              width: 70,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: jadwal.isBentrok
                    ? Colors.red.withOpacity(0.08)
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    jadwal.hari,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: jadwal.isBentrok
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    jadwal.waktuMulai,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    jadwal.waktuBerakhir,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(jadwal.mataPelajaran,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    'Kelas: ${jadwal.namaKelas ?? jadwal.kelasId}',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (jadwal.isBentrok)
              Tooltip(
                message: 'Jadwal ini bentrok!',
                child: Icon(Icons.warning_amber_rounded,
                    color: Colors.red.shade400),
              ),
          ],
        ),
      ),
    );
  }
}
