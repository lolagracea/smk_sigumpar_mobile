// lib/presentation/features/wakil_kepsek/screens/laporan_wakil_screen.dart
//
// Laporan Ringkas Akademik — Wakil Kepala Sekolah.
// Sama persis dengan WakakurLaporanPage.jsx di web (3 tab):
//   Tab 1 – Absensi Guru  → GET /api/learning/absensi-guru  (learning-service)
//   Tab 2 – Jadwal        → GET /api/academic/jadwal         (academic-service)
//   Tab 3 – Perangkat     → GET /api/learning/perangkat      (learning-service)
//
// Tidak ada perubahan di microservice.

import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';

class LaporanWakilScreen extends StatefulWidget {
  const LaporanWakilScreen({super.key});

  @override
  State<LaporanWakilScreen> createState() => _LaporanWakilScreenState();
}

class _LaporanWakilScreenState extends State<LaporanWakilScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── State ─────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _absensiRows  = [];
  List<Map<String, dynamic>> _jadwalRows   = [];
  List<Map<String, dynamic>> _perangkatRows= [];
  bool _loadingAbsensi  = false;
  bool _loadingJadwal   = false;
  bool _loadingPerangkat= false;

  // ── Filter ────────────────────────────────────────────────────────────────
  String _tanggal      = _todayStr();
  String _searchAbsensi= '';
  String _searchJadwal = '';

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() {
    return Future.wait([_loadAbsensi(), _loadJadwal(), _loadPerangkat()]);
  }

  // ── Loaders (endpoint dari microservice asli) ─────────────────────────────

  Future<void> _loadAbsensi() async {
    setState(() => _loadingAbsensi = true);
    try {
      final dio = sl<DioClient>();
      // GET /api/learning/absensi-guru?tanggal=YYYY-MM-DD
      final resp = await dio.get(
        ApiEndpoints.teacherAttendance,
        queryParameters: _tanggal.isNotEmpty ? {'tanggal': _tanggal} : null,
      );
      final raw = resp.data;
      setState(() {
        _absensiRows = _toList(raw);
      });
    } catch (_) {
    } finally {
      setState(() => _loadingAbsensi = false);
    }
  }

  Future<void> _loadJadwal() async {
    setState(() => _loadingJadwal = true);
    try {
      final dio = sl<DioClient>();
      // GET /api/academic/jadwal
      final resp = await dio.get(ApiEndpoints.schedules);
      setState(() { _jadwalRows = _toList(resp.data); });
    } catch (_) {
    } finally {
      setState(() => _loadingJadwal = false);
    }
  }

  Future<void> _loadPerangkat() async {
    setState(() => _loadingPerangkat = true);
    try {
      final dio = sl<DioClient>();
      // GET /api/learning/perangkat
      final resp = await dio.get(ApiEndpoints.learningDevices);
      setState(() { _perangkatRows = _toList(resp.data); });
    } catch (_) {
    } finally {
      setState(() => _loadingPerangkat = false);
    }
  }

  List<Map<String, dynamic>> _toList(dynamic raw) {
    if (raw is List) return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (raw is Map)  return ((raw['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }

  // ── Filtered ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredAbsensi {
    if (_searchAbsensi.isEmpty) return _absensiRows;
    final q = _searchAbsensi.toLowerCase();
    return _absensiRows.where((r) =>
      (r['namaGuru'] ?? r['nama_guru'] ?? '').toString().toLowerCase().contains(q)).toList();
  }

  List<Map<String, dynamic>> get _filteredJadwal {
    if (_searchJadwal.isEmpty) return _jadwalRows;
    final q = _searchJadwal.toLowerCase();
    return _jadwalRows.where((r) =>
      (r['mata_pelajaran'] ?? '').toString().toLowerCase().contains(q) ||
      (r['nama_kelas'] ?? '').toString().toLowerCase().contains(q) ||
      (r['nama_guru'] ?? '').toString().toLowerCase().contains(q)).toList();
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Map<String, int> get _absensiStats {
    final m = <String,int>{'total':0,'hadir':0,'terlambat':0,'izin':0,'sakit':0,'alpa':0};
    for (final r in _absensiRows) {
      m['total'] = m['total']! + 1;
      final s = (r['status'] ?? '').toString().toLowerCase();
      if (m.containsKey(s)) m[s] = m[s]! + 1;
    }
    return m;
  }

  Map<String,int> get _jadwalStats => {
    'total': _jadwalRows.length,
    'guru' : _jadwalRows.map((r)=>r['guru_id']).whereType<int>().toSet().length,
    'kelas': _jadwalRows.map((r)=>r['kelas_id']).whereType<int>().toSet().length,
  };

  Map<String,int> get _perangkatStats => {
    'total'  : _perangkatRows.length,
    'lengkap': _perangkatRows.where((d)=>d['status']=='lengkap').length,
    'belum'  : _perangkatRows.where((d)=>d['status']!='lengkap').length,
    'guru'   : _perangkatRows.map((d)=>d['guru_id']).whereType<int>().toSet().length,
  };

  static const _statusColors = {
    'hadir'    : Color(0xFF16A34A),
    'terlambat': Color(0xFFD97706),
    'izin'     : Color(0xFF2563EB),
    'sakit'    : Color(0xFFEA580C),
    'alpa'     : Color(0xFFDC2626),
  };

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aStats  = _absensiStats;
    final pStats  = _perangkatStats;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Laporan Ringkas Akademik', style: TextStyle(fontSize: 15)),
            Text(
              'Rekap absensi · jadwal · perangkat',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB), // 🔵 BLUE SAMA
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: '📋 Absensi (${_absensiRows.length})'),
            Tab(text: '📅 Jadwal (${_jadwalRows.length})'),
            Tab(text: '📁 Perangkat (${_perangkatRows.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary 4 kartu (sama seperti web)
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _MiniStat('Hadir',      '${aStats['hadir']}',   const Color(0xFF16A34A)),
                _MiniStat('Alpa/Izin',
                    '${(aStats['alpa']??0)+(aStats['izin']??0)+(aStats['sakit']??0)}',
                    const Color(0xFFDC2626)),
                _MiniStat('Total Jadwal','${_jadwalRows.length}', const Color(0xFF2563EB)),
                _MiniStat('Perangkat OK','${pStats['lengkap']}', const Color(0xFF7C3AED)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAbsensiTab(isDark),
                _buildJadwalTab(isDark),
                _buildPerangkatTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 1: Absensi Guru ───────────────────────────────────────────────────

  Widget _buildAbsensiTab(bool isDark) {
    final stats    = _absensiStats;
    final filtered = _filteredAbsensi;

    return Column(
      children: [
        Container(
          color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Mini stats row (sama seperti web — 5 kolom)
              Row(
                children: [
                  _MiniStat('Total',     '${stats['total']}',     Colors.grey),
                  _MiniStat('Hadir',     '${stats['hadir']}',     const Color(0xFF16A34A)),
                  _MiniStat('Terlambat', '${stats['terlambat']}', const Color(0xFFD97706)),
                  _MiniStat('Izin/Sakit','${(stats['izin']??0)+(stats['sakit']??0)}',
                      const Color(0xFF2563EB)),
                  _MiniStat('Alpa',      '${stats['alpa']}',      const Color(0xFFDC2626)),
                ],
              ),
              const SizedBox(height: 10),
              // Date picker + search
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _tanggal =
                                '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
                          });
                          _loadAbsensi();
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          suffixIcon: const Icon(Icons.calendar_today, size: 16),
                        ),
                        child: Text(_tanggal,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Cari nama guru...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (v) => setState(() => _searchAbsensi = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingAbsensi
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)))
              : filtered.isEmpty
                  ? _emptyState(Icons.fact_check_outlined, 'Belum ada data absensi')
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final row    = filtered[i];
                        final status = (row['status'] ?? '—').toString();
                        final color  = _statusColors[status.toLowerCase()] ?? Colors.grey;
                        final nama   = (row['namaGuru'] ?? row['nama_guru'] ?? '—').toString();
                        final mapel  = (row['mataPelajaran'] ?? row['mata_pelajaran'] ?? '—').toString();
                        final jam    = (row['jamMasuk'] ?? row['jam_masuk'] ?? '').toString();
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(left: BorderSide(color: color, width: 4)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(mapel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    if (jam.isNotEmpty)
                                      Text('⏰ ${jam.length >= 5 ? jam.substring(0,5) : jam}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(status.toUpperCase(),
                                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ── TAB 2: Jadwal ─────────────────────────────────────────────────────────

  Widget _buildJadwalTab(bool isDark) {
    final stats    = _jadwalStats;
    final filtered = _filteredJadwal;

    return Column(
      children: [
        Container(
          color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  _MiniStat(
                    'Total Jam',
                    '${stats['total']}',
                    Theme.of(context).colorScheme.primary,
                  ),
                  _MiniStat('Guru',      '${stats['guru']}',  Colors.blue),
                  _MiniStat('Kelas',     '${stats['kelas']}', Colors.purple),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Cari mapel, kelas, guru...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (v) => setState(() => _searchJadwal = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingJadwal
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)))
              : filtered.isEmpty
                  ? _emptyState(Icons.event_busy, 'Belum ada data jadwal')
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final r      = filtered[i];
                        final hari   = (r['hari'] ?? '—').toString();
                        final mulai  = (r['waktu_mulai'] ?? '').toString();
                        final selesai= (r['waktu_berakhir'] ?? '').toString();
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  hari.length >= 3 ? hari.substring(0,3) : hari,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['mata_pelajaran']?.toString() ?? '—',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text('${r['nama_kelas'] ?? '—'} • ${r['nama_guru'] ?? '—'}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(
                                        '${mulai.length >= 5 ? mulai.substring(0,5) : mulai} – '
                                        '${selesai.length >= 5 ? selesai.substring(0,5) : selesai}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ── TAB 3: Perangkat Pembelajaran ─────────────────────────────────────────

  Widget _buildPerangkatTab(bool isDark) {
    final stats = _perangkatStats;

    return Column(
      children: [
        Container(
          color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _MiniStat('Total',   '${stats['total']}',   Colors.grey),
              _MiniStat('Lengkap', '${stats['lengkap']}', const Color(0xFF16A34A)),
              _MiniStat('Belum',   '${stats['belum']}',   const Color(0xFFDC2626)),
              _MiniStat('Guru',    '${stats['guru']}',    Colors.blue),
            ],
          ),
        ),
        Expanded(
          child: _loadingPerangkat
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)))
              : _perangkatRows.isEmpty
                  ? _emptyState(Icons.folder_open, 'Belum ada data perangkat')
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _perangkatRows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final d        = _perangkatRows[i];
                        final isLengkap= d['status'] == 'lengkap';
                        final namaGuru = (d['nama_guru'] ??
                            (d['guru_id'] != null ? 'Guru #${d['guru_id']}' : '—')).toString();
                        final namaDok  = (d['nama_dokumen'] ?? d['nama_perangkat'] ?? '—').toString();
                        final jenis    = (d['jenis_dokumen'] ?? d['jenis'] ?? '—').toString();
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                color: isLengkap ? const Color(0xFF16A34A) : Colors.orange,
                                width: 4,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(namaDok, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(namaGuru, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                                          borderRadius: BorderRadius.circular(4)),
                                      child: Text(jenis,
                                          style: const TextStyle(fontSize: 10, color: Color(0xFFEA580C), fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: (isLengkap ? Colors.green : Colors.orange).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  isLengkap ? '✓ Lengkap' : '⏳ Belum',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isLengkap ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(msg, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

// ─── Mini stat widget ─────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      );
}
