import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wakil_kepsek_provider.dart';

const _hariOrder = {
  'Senin': 1, 'Selasa': 2, 'Rabu': 3,
  'Kamis': 4, 'Jumat': 5, 'Sabtu': 6, 'Minggu': 7,
};

const _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

String _formatTime(String? t) {
  if (t == null || t.isEmpty) return '—';
  return t.substring(0, t.length >= 5 ? 5 : t.length);
}

class MonitoringJadwalScreen extends StatelessWidget {
  const MonitoringJadwalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = ctx.read<WakilKepsekProvider>();
        provider.fetchJadwal();
        return provider;
      },
      child: const _JadwalView(),
    );
  }
}

class _JadwalView extends StatefulWidget {
  const _JadwalView();

  @override
  State<_JadwalView> createState() => _JadwalViewState();
}

class _JadwalViewState extends State<_JadwalView> {
  String _filterHari = '';
  String _filterKelas = '';
  String _filterMapel = '';
  String _filterGuru = '';
  bool _showBentrok = false;

  Set<int> _detectBentrok(List<Map<String, dynamic>> rows) {
    final ids = <int>{};
    for (int i = 0; i < rows.length; i++) {
      for (int j = i + 1; j < rows.length; j++) {
        final a = rows[i];
        final b = rows[j];
        if (a['guru_id'] == null || b['guru_id'] == null) continue;
        if (a['guru_id'] != b['guru_id']) continue;
        if (a['hari'] != b['hari']) continue;
        final aStart = a['waktu_mulai'] ?? '';
        final aEnd = a['waktu_berakhir'] ?? '';
        final bStart = b['waktu_mulai'] ?? '';
        final bEnd = b['waktu_berakhir'] ?? '';
        if (aStart.compareTo(bEnd) < 0 && bStart.compareTo(aEnd) < 0) {
          ids.add(a['id'] as int? ?? 0);
          ids.add(b['id'] as int? ?? 0);
        }
      }
    }
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monitoring Jadwal', style: TextStyle(fontSize: 16)),
            Text('Pantau jadwal seluruh kelas & guru', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<WakilKepsekProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingJadwal) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)));
          }
          if (provider.errorJadwal != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(provider.errorJadwal!),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: provider.fetchJadwal, child: const Text('Coba Lagi')),
                ],
              ),
            );
          }

          final rows = provider.jadwalList;
          final bentrokIds = _detectBentrok(rows);
          final totalBentrok = bentrokIds.length;

          // Filter
          var filtered = rows.where((r) {
            if (_filterHari.isNotEmpty && r['hari'] != _filterHari) return false;
            if (_filterKelas.isNotEmpty) {
              final nama = (r['nama_kelas'] ?? '').toString().toLowerCase();
              if (!nama.contains(_filterKelas.toLowerCase())) return false;
            }
            if (_filterMapel.isNotEmpty) {
              final mapel = (r['mata_pelajaran'] ?? '').toString().toLowerCase();
              if (!mapel.contains(_filterMapel.toLowerCase())) return false;
            }
            if (_filterGuru.isNotEmpty) {
              final guru = (r['nama_guru'] ?? '').toString().toLowerCase();
              if (!guru.contains(_filterGuru.toLowerCase())) return false;
            }
            if (_showBentrok && !bentrokIds.contains(r['id'] as int? ?? 0)) return false;
            return true;
          }).toList();

          filtered.sort((a, b) {
            final hA = _hariOrder[a['hari']] ?? 9;
            final hB = _hariOrder[b['hari']] ?? 9;
            if (hA != hB) return hA.compareTo(hB);
            return (a['waktu_mulai'] ?? '').compareTo(b['waktu_mulai'] ?? '');
          });

          final totalJam = rows.length;
          final totalGuru = rows.map((r) => r['guru_id']).where((id) => id != null).toSet().length;
          final totalKelas = rows.map((r) => r['kelas_id']).where((id) => id != null).toSet().length;

          return Column(
            children: [
              // Stats
              Container(
                color: const Color(0xFFEA580C),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _StatCard(label: 'Total Jam', value: '$totalJam', color: Colors.white),
                    const SizedBox(width: 8),
                    _StatCard(label: 'Guru', value: '$totalGuru', color: Colors.white),
                    const SizedBox(width: 8),
                    _StatCard(label: 'Kelas', value: '$totalKelas', color: Colors.white),
                    const SizedBox(width: 8),
                    _StatCard(
                      label: 'Bentrok',
                      value: '$totalBentrok',
                      color: totalBentrok > 0 ? Colors.yellow : Colors.white,
                    ),
                  ],
                ),
              ),

              // Bentrok warning
              if (totalBentrok > 0)
                Container(
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Terdeteksi $totalBentrok jadwal berpotensi bentrok!',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _showBentrok = !_showBentrok),
                        child: Text(_showBentrok ? 'Semua' : 'Lihat', style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),

              // Filter
              Container(
                color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _filterHari.isEmpty ? null : _filterHari,
                            decoration: InputDecoration(
                              labelText: 'Hari',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('Semua Hari')),
                              ..._hariList.map((h) => DropdownMenuItem(value: h, child: Text(h))),
                            ],
                            onChanged: (v) => setState(() => _filterHari = v ?? ''),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Kelas',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (v) => setState(() => _filterKelas = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Mata Pelajaran',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (v) => setState(() => _filterMapel = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Guru',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (v) => setState(() => _filterGuru = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() {
                            _filterHari = '';
                            _filterKelas = '';
                            _filterMapel = '';
                            _filterGuru = '';
                            _showBentrok = false;
                          }),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          child: const Text('Reset', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Rekapitulasi per hari
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _hariList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final hari = _hariList[i];
                    final count = rows.where((r) => r['hari'] == hari).length;
                    final isActive = _filterHari == hari;
                    return GestureDetector(
                      onTap: () => setState(() => _filterHari = isActive ? '' : hari),
                      child: Container(
                        width: 60,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFEA580C) : (isDark ? const Color(0xFF1E1E3A) : Colors.white),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isActive ? const Color(0xFFEA580C) : Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(hari.substring(0, 3), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white : null)),
                            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isActive ? Colors.white : null)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Table
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_busy, size: 60, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(rows.isEmpty ? 'Belum ada data jadwal' : 'Tidak ada yang sesuai filter', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: provider.fetchJadwal,
                        color: const Color(0xFFEA580C),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final r = filtered[i];
                            final isBentrok = bentrokIds.contains(r['id'] as int? ?? 0);

                            return Container(
                              decoration: BoxDecoration(
                                color: isBentrok
                                    ? Colors.red.shade50
                                    : (isDark ? const Color(0xFF1E1E3A) : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isBentrok ? Colors.red.shade200 : Colors.transparent,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  // Hari badge
                                  Container(
                                    width: 52,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEA580C).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      (r['hari'] ?? '—').toString().substring(0, 3),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r['mata_pelajaran'] ?? '—',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${r['nama_kelas'] ?? '—'} • ${r['nama_guru'] ?? '—'}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          '${_formatTime(r['waktu_mulai'])} – ${_formatTime(r['waktu_berakhir'])}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isBentrok)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('⚠️ Bentrok', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('✓ OK', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}
