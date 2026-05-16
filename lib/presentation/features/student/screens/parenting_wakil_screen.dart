import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';

class _ParentingRow {
  final int id;
  final int? kelasId;
  final String namaKelas;
  final String agenda;
  final String ringkasan;
  final String tanggal;
  final int kehadiranOrtu;

  _ParentingRow({
    required this.id,
    this.kelasId,
    required this.namaKelas,
    required this.agenda,
    required this.ringkasan,
    required this.tanggal,
    required this.kehadiranOrtu,
  });

  factory _ParentingRow.fromJson(Map<String, dynamic> json) {
    return _ParentingRow(
      id: json['id'] ?? 0,
      kelasId: json['kelas_id'] as int?,
      namaKelas: json['nama_kelas'] ?? 'Kelas #${json['kelas_id']}',
      agenda: json['agenda'] ?? '—',
      ringkasan: json['ringkasan'] ?? '—',
      tanggal: _fmtDate(json['tanggal']),
      kehadiranOrtu: int.tryParse('${json['kehadiran_ortu'] ?? 0}') ?? 0,
    );
  }

  static String _fmtDate(dynamic v) {
    if (v == null) return '—';
    try {
      final d = DateTime.parse(v.toString());
      const m = [
        'Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Agu','Sep','Okt','Nov','Des'
      ];
      return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return v.toString().split('T').first;
    }
  }
}

class ParentingWakilScreen extends StatefulWidget {
  const ParentingWakilScreen({super.key});

  @override
  State<ParentingWakilScreen> createState() => _ParentingWakilScreenState();
}

class _ParentingWakilScreenState extends State<ParentingWakilScreen> {
  List<_ParentingRow> _rows = [];
  List<Map<String, dynamic>> _kelasList = [];

  bool _loading = false;
  String? _error;

  String _filterKelasId = '';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadKelas();
    _loadData();
  }

  Future<void> _loadKelas() async {
    try {
      final dio = sl<DioClient>();
      final resp = await dio.get(ApiEndpoints.classes);
      final raw = resp.data;

      final list = raw is List
          ? raw
          : (raw is Map ? raw['data'] as List? ?? [] : []);

      setState(() {
        _kelasList =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();

      final params = <String, dynamic>{};
      if (_filterKelasId.isNotEmpty) {
        params['kelas_id'] = _filterKelasId;
      }

      final resp = await dio.get(
        ApiEndpoints.parenting,
        queryParameters: params.isNotEmpty ? params : null,
      );

      final raw = resp.data;
      final list = raw is List
          ? raw
          : (raw is Map ? raw['data'] as List? ?? [] : []);

      setState(() {
        _rows = list
            .map((e) => _ParentingRow.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      setState(() {
        _error = 'Gagal memuat data parenting';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<_ParentingRow> get _filtered {
    final q = _search.toLowerCase();

    return _rows.where((r) {
      if (_search.isNotEmpty &&
          !r.agenda.toLowerCase().contains(q) &&
          !r.ringkasan.toLowerCase().contains(q) &&
          !r.namaKelas.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    final totalOrtu =
        _rows.fold(0, (sum, r) => sum + r.kehadiranOrtu);

    final bgColor =
        isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6);

    final cardColor =
        isDark ? const Color(0xFF1E1E3A) : Colors.white;

    final textColor =
        isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monitoring Parenting', style: TextStyle(fontSize: 16)),
            Text(
              'Data kegiatan parenting per kelas',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB), // 🔵 BLUE
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),

      body: Column(
        children: [
          // ───────────────── Stats (FIXED THEME) ─────────────────
          Container(
            color: cardColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _StatBox(
                  label: 'Total Kegiatan',
                  value: '${_rows.length}',
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _StatBox(
                  label: 'Total Ortu Hadir',
                  value: '$totalOrtu',
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _StatBox(
                  label: 'Kelas Terlibat',
                  value: '${_rows.map((r) => r.kelasId).toSet().length}',
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // ───────────────── FILTER ─────────────────
          Container(
            color: cardColor,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value:
                        _filterKelasId.isEmpty ? null : _filterKelasId,
                    decoration: InputDecoration(
                      labelText: 'Filter Kelas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Semua Kelas'),
                      ),
                      ..._kelasList.map((k) {
                        final id = k['id']?.toString() ?? '';
                        final nama =
                            k['nama_kelas'] ?? 'Kelas #$id';

                        return DropdownMenuItem(
                          value: id,
                          child: Text(nama.toString()),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      setState(() => _filterKelasId = v ?? '');
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Cari agenda...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ],
            ),
          ),

          // ───────────────── CONTENT ─────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFEA580C),
                    ),
                  )
                : _error != null
                    ? Center(child: Text(_error!))
                    : filtered.isEmpty
                        ? const Center(
                            child: Text('Tidak ada data'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: const Color(0xFFEA580C),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final row = filtered[i];

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row.namaKelas,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        row.agenda,
                                        style: TextStyle(
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${row.kehadiranOrtu} orang tua hadir',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2A2A40)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white24
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF111827),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isDark
                    ? Colors.white70
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}