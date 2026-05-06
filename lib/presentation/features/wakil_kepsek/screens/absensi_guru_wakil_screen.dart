import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';

// Absensi Guru data model (read-only for Wakil Kepsek)
class _AbsensiGuruRow {
  final int id;
  final String namaGuru;
  final String mataPelajaran;
  final String tanggal;
  final String? jamMasuk;
  final String status;
  final String keterangan;

  _AbsensiGuruRow({
    required this.id,
    required this.namaGuru,
    required this.mataPelajaran,
    required this.tanggal,
    this.jamMasuk,
    required this.status,
    required this.keterangan,
  });

  factory _AbsensiGuruRow.fromJson(Map<String, dynamic> json) {
    return _AbsensiGuruRow(
      id: json['id'] ?? json['id_absensiGuru'] ?? json['id_absensi_guru'] ?? 0,
      namaGuru: json['namaGuru'] ?? json['nama_guru'] ?? json['nama'] ?? json['nama_lengkap'] ?? '—',
      mataPelajaran: json['mataPelajaran'] ?? json['mata_pelajaran'] ?? json['mapel'] ?? json['nama_mapel'] ?? '—',
      tanggal: _parseDate(json['tanggal']),
      jamMasuk: json['jamMasuk'] ?? json['jam_masuk'] ?? json['jam_masuk_guru'],
      status: (json['status'] ?? '—').toString(),
      keterangan: json['keterangan'] ?? '—',
    );
  }

  static String _parseDate(dynamic val) {
    if (val == null) return '—';
    final s = val.toString();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) return s;
    try {
      final d = DateTime.parse(s);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return s;
    }
  }
}

const _statusColors = {
  'hadir': Color(0xFF16A34A),
  'terlambat': Color(0xFFD97706),
  'izin': Color(0xFF2563EB),
  'sakit': Color(0xFFEA580C),
  'alpa': Color(0xFFDC2626),
};

Color _getStatusColor(String status) =>
    _statusColors[status.toLowerCase()] ?? Colors.grey;

class AbsensiGuruWakilScreen extends StatefulWidget {
  const AbsensiGuruWakilScreen({super.key});

  @override
  State<AbsensiGuruWakilScreen> createState() => _AbsensiGuruWakilScreenState();
}

class _AbsensiGuruWakilScreenState extends State<AbsensiGuruWakilScreen> {
  List<_AbsensiGuruRow> _rows = [];
  bool _loading = false;
  String? _error;

  String _tanggal = _todayStr();
  String _searchGuru = '';
  String _filterStatus = '';
  String _filterMapel = '';

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = sl<DioClient>();
      final params = <String, dynamic>{};
      if (_tanggal.isNotEmpty) params['tanggal'] = _tanggal;

      final response = await dio.get(
        ApiEndpoints.absensiGuru,
        queryParameters: params,
      );
      final raw = response.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map) {
        list = raw['data'] is List ? raw['data'] as List : [];
      }
      setState(() {
        _rows = list.map((e) => _AbsensiGuruRow.fromJson(e as Map<String, dynamic>)).toList();
      });
    } catch (e) {
      setState(() { _error = 'Gagal memuat data absensi guru'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  List<_AbsensiGuruRow> get _filtered {
    return _rows.where((r) {
      if (_searchGuru.isNotEmpty && !r.namaGuru.toLowerCase().contains(_searchGuru.toLowerCase())) return false;
      if (_filterStatus.isNotEmpty && r.status.toLowerCase() != _filterStatus.toLowerCase()) return false;
      if (_filterMapel.isNotEmpty && !r.mataPelajaran.toLowerCase().contains(_filterMapel.toLowerCase())) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    // Stats
    final totalHadir = _rows.where((r) => r.status.toLowerCase() == 'hadir').length;
    final totalTerlambat = _rows.where((r) => r.status.toLowerCase() == 'terlambat').length;
    final totalAlpa = _rows.where((r) => r.status.toLowerCase() == 'alpa').length;
    final totalIzinSakit = _rows.where((r) => ['izin', 'sakit'].contains(r.status.toLowerCase())).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rekap Absensi Guru', style: TextStyle(fontSize: 16)),
            Text('Monitoring kehadiran guru harian', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats
          Container(
            color: const Color(0xFFEA580C),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _StatTile(label: 'Hadir', value: '$totalHadir', color: Colors.greenAccent),
                const SizedBox(width: 6),
                _StatTile(label: 'Terlambat', value: '$totalTerlambat', color: Colors.yellowAccent),
                const SizedBox(width: 6),
                _StatTile(label: 'Izin/Sakit', value: '$totalIzinSakit', color: Colors.lightBlueAccent),
                const SizedBox(width: 6),
                _StatTile(label: 'Alpa', value: '$totalAlpa', color: Colors.redAccent),
              ],
            ),
          ),

          // Filter panel
          Container(
            color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Date picker
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
                              _tanggal = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                            });
                            _loadData();
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tanggal',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            suffixIcon: const Icon(Icons.calendar_today, size: 16),
                          ),
                          child: Text(_tanggal, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus.isEmpty ? null : _filterStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Semua Status')),
                          DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                          DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                          DropdownMenuItem(value: 'izin', child: Text('Izin')),
                          DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                          DropdownMenuItem(value: 'alpa', child: Text('Alpa')),
                        ],
                        onChanged: (v) => setState(() => _filterStatus = v ?? ''),
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
                          labelText: 'Cari nama guru...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (v) => setState(() => _searchGuru = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Mata pelajaran...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (v) => setState(() => _filterMapel = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _tanggal = _todayStr();
                          _searchGuru = '';
                          _filterStatus = '';
                          _filterMapel = '';
                        });
                        _loadData();
                      },
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                      child: const Text('Reset', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 8),
                            Text(_error!),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fact_check_outlined, size: 60, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  _rows.isEmpty ? 'Belum ada data absensi untuk tanggal ini' : 'Tidak ada yang sesuai filter',
                                  style: const TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: const Color(0xFFEA580C),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, i) {
                                final row = filtered[i];
                                final statusColor = _getStatusColor(row.status);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border(
                                      left: BorderSide(color: statusColor, width: 4),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              row.namaGuru,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              row.mataPelajaran,
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                            if (row.jamMasuk != null) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    _formatTime(row.jamMasuk!),
                                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  ),
                                                  if (row.keterangan != '—') ...[
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        row.keterangan,
                                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: statusColor.withOpacity(0.4)),
                                            ),
                                            child: Text(
                                              row.status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            row.tanggal,
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        ],
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

  String _formatTime(String val) {
    try {
      final d = DateTime.parse(val);
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';
    } catch (_) {
      return val.length >= 5 ? val.substring(0, 5) : val;
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.color});

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
            Text(label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.9)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
