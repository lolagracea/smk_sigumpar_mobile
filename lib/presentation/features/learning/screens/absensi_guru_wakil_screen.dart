import 'package:flutter/material.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';

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
      id: json['id'] ?? 0,
      namaGuru: json['namaGuru'] ?? '—',
      mataPelajaran: json['mataPelajaran'] ?? '—',
      tanggal: json['tanggal']?.toString() ?? '—',
      jamMasuk: json['jamMasuk']?.toString(),
      status: (json['status'] ?? '—').toString(),
      keterangan: json['keterangan'] ?? '—',
    );
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
  State<AbsensiGuruWakilScreen> createState() =>
      _AbsensiGuruWakilScreenState();
}

class _AbsensiGuruWakilScreenState extends State<AbsensiGuruWakilScreen> {
  List<_AbsensiGuruRow> _rows = [];
  bool _loading = false;
  String? _error;

  String _tanggal = '';
  String _search = '';
  String _filterStatus = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();

      final resp = await dio.get(
        ApiEndpoints.absensiGuru,
        queryParameters: _tanggal.isNotEmpty
            ? {'tanggal': _tanggal}
            : null,
      );

      final raw = resp.data;
      final list = raw is List
          ? raw
          : (raw is Map ? raw['data'] ?? [] : []);

      _rows = (list as List)
          .map((e) => _AbsensiGuruRow.fromJson(e))
          .toList();

      setState(() {});
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  List<_AbsensiGuruRow> get _filtered {
    return _rows.where((r) {
      if (_search.isNotEmpty &&
          !r.namaGuru.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      if (_filterStatus.isNotEmpty &&
          r.status.toLowerCase() != _filterStatus) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filtered = _filtered;

    final totalHadir =
        _rows.where((e) => e.status == 'hadir').length;
    final totalTerlambat =
        _rows.where((e) => e.status == 'terlambat').length;
    final totalAlpa =
        _rows.where((e) => e.status == 'alpa').length;

    return Scaffold(
      backgroundColor: colorScheme.background,

      // ================= APPBAR =================
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rekap Absensi Guru', style: TextStyle(fontSize: 16)),
            Text(
              'Monitoring kehadiran guru harian',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),

      body: Column(
        children: [
          // ================= STAT BOX (FIX THEME) =================
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                _StatTile(
                  label: 'Hadir',
                  value: '$totalHadir',
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                _StatTile(
                  label: 'Terlambat',
                  value: '$totalTerlambat',
                  color: Colors.orange,
                ),
                const SizedBox(width: 6),
                _StatTile(
                  label: 'Alpa',
                  value: '$totalAlpa',
                  color: Colors.red,
                ),
              ],
            ),
          ),

          // ================= FILTER =================
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari guru...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ],
            ),
          ),

          // ================= CONTENT =================
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada data',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final r = filtered[i];
                              final statusColor =
                                  _getStatusColor(r.status);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border(
                                    left: BorderSide(
                                      color: statusColor,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.namaGuru,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            r.mataPelajaran,
                                            style: TextStyle(
                                              color: colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        r.status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
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
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}