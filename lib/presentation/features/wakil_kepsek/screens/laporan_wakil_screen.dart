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

  // ── Absensi state ──
  List<Map<String, dynamic>> _absensiRows = [];
  bool _loadingAbsensi = false;

  // ── Jadwal state ──
  List<Map<String, dynamic>> _jadwalRows = [];
  bool _loadingJadwal = false;

  // ── Perangkat state ──
  List<Map<String, dynamic>> _perangkatRows = [];
  bool _loadingPerangkat = false;

  // ── Filter ──
  String _tanggal = _todayStr();
  String _searchAbsensi = '';
  String _searchJadwal = '';

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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

  Future<void> _loadAll() async {
    _loadAbsensi();
    _loadJadwal();
    _loadPerangkat();
  }

  Future<void> _loadAbsensi() async {
    setState(() => _loadingAbsensi = true);
    try {
      final dio = sl<DioClient>();
      final resp = await dio.get(
        ApiEndpoints.teacherAttendance,
        queryParameters: _tanggal.isNotEmpty ? {'tanggal': _tanggal} : null,
      );
      final raw = resp.data;
      List<dynamic> list =
          raw is List ? raw : (raw is Map ? raw['data'] as List? ?? [] : []);
      setState(() {
        _absensiRows =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
      final resp = await dio.get(ApiEndpoints.schedules);
      final raw = resp.data;
      List<dynamic> list =
          raw is List ? raw : (raw is Map ? raw['data'] as List? ?? [] : []);
      setState(() {
        _jadwalRows =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (_) {
    } finally {
      setState(() => _loadingJadwal = false);
    }
  }

  Future<void> _loadPerangkat() async {
    setState(() => _loadingPerangkat = true);
    try {
      final dio = sl<DioClient>();
      final resp = await dio.get(ApiEndpoints.learningDevices);
      final raw = resp.data;
      List<dynamic> list =
          raw is List ? raw : (raw is Map ? raw['data'] as List? ?? [] : []);
      setState(() {
        _perangkatRows =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (_) {
    } finally {
      setState(() => _loadingPerangkat = false);
    }
  }

  // ── Filtered ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredAbsensi {
    if (_searchAbsensi.isEmpty) return _absensiRows;
    final q = _searchAbsensi.toLowerCase();
    return _absensiRows.where((r) {
      final nama =
          (r['namaGuru'] ?? r['nama_guru'] ?? '').toString().toLowerCase();
      return nama.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredJadwal {
    if (_searchJadwal.isEmpty) return _jadwalRows;
    final q = _searchJadwal.toLowerCase();
    return _jadwalRows.where((r) {
      return (r['mata_pelajaran'] ?? '').toString().toLowerCase().contains(q) ||
          (r['nama_kelas'] ?? '').toString().toLowerCase().contains(q) ||
          (r['nama_guru'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Map<String, int> get _absensiStats {
    final m = <String, int>{
      'total': 0,
      'hadir': 0,
      'terlambat': 0,
      'izin': 0,
      'sakit': 0,
      'alpa': 0
    };
    for (final r in _absensiRows) {
      m['total'] = m['total']! + 1;
      final s = (r['status'] ?? '').toString().toLowerCase();
      if (m.containsKey(s)) m[s] = m[s]! + 1;
    }
    return m;
  }

  Map<String, int> get _jadwalStats => {
        'total': _jadwalRows.length,
        'guru': _jadwalRows
            .map((r) => r['guru_id'])
            .where((id) => id != null)
            .toSet()
            .length,
        'kelas': _jadwalRows
            .map((r) => r['kelas_id'])
            .where((id) => id != null)
            .toSet()
            .length,
      };

  Map<String, int> get _perangkatStats => {
        'total': _perangkatRows.length,
        'lengkap':
            _perangkatRows.where((d) => d['status'] == 'lengkap').length,
        'belum':
            _perangkatRows.where((d) => d['status'] != 'lengkap').length,
        'guru': _perangkatRows
            .map((d) => d['guru_id'])
            .where((id) => id != null)
            .toSet()
            .length,
      };

  static const _statusColors = {
    'hadir': Color(0xFF16A34A),
    'terlambat': Color(0xFFD97706),
    'izin': Color(0xFF2563EB),
    'sakit': Color(0xFFEA580C),
    'alpa': Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final absensiStats = _absensiStats;
    final perangkatStats = _perangkatStats;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Laporan Ringkas Akademik', style: TextStyle(fontSize: 15)),
            Text('Rekap absensi · jadwal · perangkat',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: '📋 Absensi (${_absensiRows.length})'),
            Tab(text: '📅 Jadwal (${_jadwalRows.length})'),
            Tab(text: '📁 Perangkat (${_perangkatRows.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Summary cards ─────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _SmallStat(
                    label: 'Hadir',
                    value: '${absensiStats['hadir']}',
                    color: const Color(0xFF16A34A)),
                _SmallStat(
                    label: 'Alpa/Izin',
                    value:
                        '${(absensiStats['alpa'] ?? 0) + (absensiStats['izin'] ?? 0) + (absensiStats['sakit'] ?? 0)}',
                    color: const Color(0xFFDC2626)),
                _SmallStat(
                    label: 'Total Jadwal',
                    value: '${_jadwalRows.length}',
                    color: const Color(0xFF2563EB)),
                _SmallStat(
                    label: 'Perangkat OK',
                    value: '${perangkatStats['lengkap']}',
                    color: const Color(0xFF7C3AED)),
              ],
            ),
          ),

          // ── Tabs ──────────────────────────────────────────────────────
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

  // ─── TAB: ABSENSI ─────────────────────────────────────────────────────────

  Widget _buildAbsensiTab(bool isDark) {
    final stats = _absensiStats;
    final filtered = _filteredAbsensi;

    return Column(
      children: [
        Container(
          color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  _SmallStat(
                      label: 'Total',
                      value: '${stats['total']}',
                      color: Colors.grey),
                  _SmallStat(
                      label: 'Hadir',
                      value: '${stats['hadir']}',
                      color: const Color(0xFF16A34A)),
                  _SmallStat(
                      label: 'Terlambat',
                      value: '${stats['terlambat']}',
                      color: const Color(0xFFD97706)),
                  _SmallStat(
                      label: 'Izin/Sakit',
                      value:
                          '${(stats['izin'] ?? 0) + (stats['sakit'] ?? 0)}',
                      color: const Color(0xFF2563EB)),
                  _SmallStat(
                      label: 'Alpa',
                      value: '${stats['alpa']}',
                      color: const Color(0xFFDC2626)),
                ],
              ),
              const SizedBox(height: 10),
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
                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
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
                          suffixIcon:
                              const Icon(Icons.calendar_today, size: 16),
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
                      onChanged: (v) =>
                          setState(() => _searchAbsensi = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingAbsensi
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFEA580C)))
              : filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fact_check_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Belum ada data absensi',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final row = filtered[i];
                        final status =
                            (row['status'] ?? '—').toString();
                        final color =
                            _statusColors[status.toLowerCase()] ??
                                Colors.grey;
                        final nama =
                            row['namaGuru'] ?? row['nama_guru'] ?? '—';
                        final mapel = row['mataPelajaran'] ??
                            row['mata_pelajaran'] ??
                            '—';
                        final jam =
                            row['jamMasuk'] ?? row['jam_masuk'] ?? '';
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E3A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                                left: BorderSide(color: color, width: 4)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(nama.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    Text(mapel.toString(),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey)),
                                    if (jam.toString().isNotEmpty)
                                      Text(
                                        '⏰ ${jam.toString().length >= 5 ? jam.toString().substring(0, 5) : jam}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: color,
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

  // ─── TAB: JADWAL ──────────────────────────────────────────────────────────

  Widget _buildJadwalTab(bool isDark) {
    final stats = _jadwalStats;
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
                  _SmallStat(
                      label: 'Total Jam',
                      value: '${stats['total']}',
                      color: const Color(0xFFEA580C)),
                  _SmallStat(
                      label: 'Guru',
                      value: '${stats['guru']}',
                      color: Colors.blue),
                  _SmallStat(
                      label: 'Kelas',
                      value: '${stats['kelas']}',
                      color: Colors.purple),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Cari mapel, kelas, guru...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (v) =>
                    setState(() => _searchJadwal = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingJadwal
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFEA580C)))
              : filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Belum ada data jadwal',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final r = filtered[i];
                        final hari = (r['hari'] ?? '—').toString();
                        final mulai =
                            (r['waktu_mulai'] ?? '').toString();
                        final selesai =
                            (r['waktu_berakhir'] ?? '').toString();
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E3A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFEA580C)
                                        .withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(6)),
                                child: Text(
                                  hari.length >= 3
                                      ? hari.substring(0, 3)
                                      : hari,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEA580C)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        r['mata_pelajaran']
                                                ?.toString() ??
                                            '—',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    Text(
                                        '${r['nama_kelas'] ?? '—'} • ${r['nama_guru'] ?? '—'}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey)),
                                    Text(
                                        '${mulai.length >= 5 ? mulai.substring(0, 5) : mulai} – ${selesai.length >= 5 ? selesai.substring(0, 5) : selesai}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey)),
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

  // ─── TAB: PERANGKAT PEMBELAJARAN ──────────────────────────────────────────

  Widget _buildPerangkatTab(bool isDark) {
    final stats = _perangkatStats;

    return Column(
      children: [
        Container(
          color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _SmallStat(
                  label: 'Total',
                  value: '${stats['total']}',
                  color: Colors.grey),
              _SmallStat(
                  label: 'Lengkap',
                  value: '${stats['lengkap']}',
                  color: const Color(0xFF16A34A)),
              _SmallStat(
                  label: 'Belum',
                  value: '${stats['belum']}',
                  color: const Color(0xFFDC2626)),
              _SmallStat(
                  label: 'Guru',
                  value: '${stats['guru']}',
                  color: Colors.blue),
            ],
          ),
        ),
        Expanded(
          child: _loadingPerangkat
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFEA580C)))
              : _perangkatRows.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Belum ada data perangkat',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _perangkatRows.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final d = _perangkatRows[i];
                        final isLengkap = d['status'] == 'lengkap';
                        final namaGuru = d['nama_guru'] ??
                            (d['guru_id'] != null
                                ? 'Guru #${d['guru_id']}'
                                : '—');
                        final namaDok = d['nama_dokumen'] ??
                            d['nama_perangkat'] ??
                            '—';
                        final jenis =
                            d['jenis_dokumen'] ?? d['jenis'] ?? '—';
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E3A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                color: isLengkap
                                    ? const Color(0xFF16A34A)
                                    : Colors.orange,
                                width: 4,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(namaDok.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    Text(namaGuru.toString(),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey)),
                                    Container(
                                      margin:
                                          const EdgeInsets.only(top: 4),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFEA580C)
                                              .withOpacity(0.10),
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: Text(
                                        jenis.toString(),
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFEA580C),
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: (isLengkap
                                            ? Colors.green
                                            : Colors.orange)
                                        .withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                child: Text(
                                  isLengkap ? '✓ Lengkap' : '⏳ Belum',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isLengkap
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
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
}

// ─── Reusable stat widget ─────────────────────────────────────────────────────

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SmallStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
