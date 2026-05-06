// lib/presentation/features/wakil_kepsek/screens/kurikulum_screen.dart
//
// Monitoring Perangkat Pembelajaran (Kurikulum) untuk Wakil Kepala Sekolah.
// Endpoint: GET /api/learning/perangkat  (learning-service — sama dengan yang
// digunakan web di WakakurPerangkatPage.jsx via learningApi.getAllPerangkat())
//
// Fitur identik dengan web:
//   • Stats: Total Dokumen, Lengkap, Belum Lengkap, Guru Terdaftar
//   • Filter: nama dokumen, guru, jenis dokumen, status
//   • List card dengan badge jenis berwarna + indikator lengkap/belum
//   • Pull-to-refresh

import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class _PerangkatRow {
  final int id;
  final int? guruId;
  final String namaGuru;
  final String namaDokumen;
  final String jenisDokumen;
  final String status;
  final String? catatan;
  final String? namaFile;
  final String? tanggalUpload;

  const _PerangkatRow({
    required this.id,
    this.guruId,
    required this.namaGuru,
    required this.namaDokumen,
    required this.jenisDokumen,
    required this.status,
    this.catatan,
    this.namaFile,
    this.tanggalUpload,
  });

  factory _PerangkatRow.fromJson(Map<String, dynamic> j) {
    return _PerangkatRow(
      id: j['id'] ?? 0,
      guruId: j['guru_id'] as int?,
      // learning-service bisa kembalikan nama_guru atau hanya guru_id
      namaGuru: j['nama_guru'] ??
          (j['guru_id'] != null ? 'Guru #${j['guru_id']}' : '—'),
      namaDokumen: j['nama_dokumen'] ?? j['nama_perangkat'] ?? '—',
      jenisDokumen: j['jenis_dokumen'] ?? j['jenis'] ?? '—',
      status: j['status'] ?? 'belum_lengkap',
      catatan: j['catatan'],
      namaFile: j['nama_file'],
      tanggalUpload: _fmtDate(j['created_at'] ?? j['tanggal_upload']),
    );
  }

  static String? _fmtDate(dynamic v) {
    if (v == null) return null;
    try {
      final d = DateTime.parse(v.toString());
      const bulan = [
        'Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Agu','Sep','Okt','Nov','Des'
      ];
      return '${d.day.toString().padLeft(2,'0')} ${bulan[d.month-1]} ${d.year}';
    } catch (_) {
      return v.toString().split('T').first;
    }
  }
}

// ─── Helpers warna badge jenis ────────────────────────────────────────────────

const _jenisColors = <String, Color>{
  'RPP'    : Color(0xFF2563EB),
  'Silabus': Color(0xFF16A34A),
  'Modul'  : Color(0xFF7C3AED),
  'Prota'  : Color(0xFFD97706),
  'Promes' : Color(0xFFEA580C),
};

Color _jenisColor(String jenis) =>
    _jenisColors[jenis] ?? const Color(0xFF6B7280);

// ─── Screen ───────────────────────────────────────────────────────────────────

class KurikulumScreen extends StatefulWidget {
  const KurikulumScreen({super.key});

  @override
  State<KurikulumScreen> createState() => _KurikulumScreenState();
}

class _KurikulumScreenState extends State<KurikulumScreen> {
  List<_PerangkatRow> _rows = [];
  bool _loading = false;
  String? _error;

  // ── Filter state (sama seperti web) ───────────────────────────────────────
  String _search       = '';   // nama dokumen
  String _filterGuru   = '';
  String _filterJenis  = '';
  String _filterStatus = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Load dari /api/learning/perangkat ─────────────────────────────────────

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = sl<DioClient>();
      // Endpoint sama dengan web: learningApi.getAllPerangkat()
      // → GET /api/learning/perangkat
      final resp = await dio.get(ApiEndpoints.learningDevices);
      final raw = resp.data;
      List<dynamic> list = [];
      if (raw is List)        list = raw;
      else if (raw is Map)    list = (raw['data'] as List?) ?? [];
      setState(() {
        _rows = list
            .map((e) => _PerangkatRow.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      setState(() => _error = 'Gagal memuat data perangkat pembelajaran');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Filtered (sama logika web) ────────────────────────────────────────────

  List<_PerangkatRow> get _filtered => _rows.where((d) {
    if (_filterJenis.isNotEmpty && d.jenisDokumen != _filterJenis) return false;
    if (_filterStatus.isNotEmpty && d.status != _filterStatus) return false;
    if (_filterGuru.isNotEmpty &&
        !d.namaGuru.toLowerCase().contains(_filterGuru.toLowerCase())) {
      return false;
    }
    if (_search.isNotEmpty &&
        !d.namaDokumen.toLowerCase().contains(_search.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();

  // ── Stats (sama seperti web) ──────────────────────────────────────────────

  int get _totalLengkap => _rows.where((d) => d.status == 'lengkap').length;
  int get _totalBelum   => _rows.where((d) => d.status != 'lengkap').length;
  int get _totalGuru    =>
      _rows.map((d) => d.guruId).whereType<int>().toSet().length;

  List<String> get _jenisList =>
      (_rows.map((d) => d.jenisDokumen).where((j) => j != '—').toSet()
          .toList()..sort());

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monitoring Perangkat Pembelajaran',
                style: TextStyle(fontSize: 15)),
            Text('Pantau kelengkapan perangkat guru',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          // ── Stats bar (4 kartu sama seperti web) ──────────────────────
          Container(
            color: const Color(0xFFEA580C),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _Stat('Total Dokumen', '${_rows.length}', Colors.white),
                const SizedBox(width: 6),
                _Stat('Lengkap', '$_totalLengkap', Colors.greenAccent),
                const SizedBox(width: 6),
                _Stat('Belum Lengkap', '$_totalBelum', Colors.redAccent),
                const SizedBox(width: 6),
                _Stat('Guru Terdaftar', '$_totalGuru',
                    Colors.lightBlueAccent),
              ],
            ),
          ),

          // ── Filter panel (sama seperti web) ───────────────────────────
          Container(
            color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Row 1: nama dokumen + guru
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: _inputDec('Nama Dokumen',
                            prefix: Icons.search),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: _inputDec('Cari Guru'),
                        onChanged: (v) => setState(() => _filterGuru = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: jenis + status + reset
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterJenis.isEmpty ? null : _filterJenis,
                        decoration: _inputDec('Jenis Dokumen'),
                        items: [
                          const DropdownMenuItem(
                              value: '', child: Text('Semua Jenis')),
                          ..._jenisList.map((j) =>
                              DropdownMenuItem(value: j, child: Text(j))),
                        ],
                        onChanged: (v) =>
                            setState(() => _filterJenis = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus.isEmpty
                            ? null
                            : _filterStatus,
                        decoration: _inputDec('Status'),
                        items: const [
                          DropdownMenuItem(
                              value: '', child: Text('Semua Status')),
                          DropdownMenuItem(
                              value: 'lengkap',
                              child: Text('Lengkap')),
                          DropdownMenuItem(
                              value: 'belum_lengkap',
                              child: Text('Belum Lengkap')),
                        ],
                        onChanged: (v) =>
                            setState(() => _filterStatus = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _search = '';
                        _filterGuru = '';
                        _filterJenis = '';
                        _filterStatus = '';
                      }),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10)),
                      child: const Text('Reset',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFEA580C)))
                : _error != null
                    ? _buildError()
                    : filtered.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: const Color(0xFFEA580C),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) =>
                                  _buildCard(filtered[i], isDark),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ── Card item ─────────────────────────────────────────────────────────────

  Widget _buildCard(_PerangkatRow doc, bool isDark) {
    final isLengkap = doc.status == 'lengkap';
    final jColor    = _jenisColor(doc.jenisDokumen);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isLengkap ? const Color(0xFF16A34A) : Colors.orange,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: badge jenis + badge status
          Row(
            children: [
              _Badge(doc.jenisDokumen, jColor),
              const Spacer(),
              _Badge(
                isLengkap ? '✓ Lengkap' : '⏳ Belum Lengkap',
                isLengkap ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Nama dokumen
          Text(doc.namaDokumen,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),

          // Guru + tanggal
          Row(
            children: [
              const Icon(Icons.person_outline, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(doc.namaGuru,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis),
              ),
              if (doc.tanggalUpload != null) ...[
                const Icon(Icons.calendar_today,
                    size: 11, color: Colors.grey),
                const SizedBox(width: 3),
                Text(doc.tanggalUpload!,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
              ],
            ],
          ),

          // Catatan
          if (doc.catatan != null && doc.catatan!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black12
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  const Icon(Icons.notes,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(doc.catatan!,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],

          // Nama file
          if (doc.namaFile != null && doc.namaFile!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(_fileIcon(doc.namaFile!),
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(doc.namaFile!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Error / empty states ──────────────────────────────────────────────────

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _loadData, child: const Text('Coba Lagi')),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _rows.isEmpty
                  ? 'Belum ada data perangkat pembelajaran'
                  : 'Tidak ada yang sesuai filter',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  InputDecoration _inputDec(String label, {IconData? prefix}) =>
      InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8)),
        isDense: true,
        prefixIcon: prefix != null ? Icon(prefix, size: 18) : null,
        contentPadding: prefix != null
            ? const EdgeInsets.symmetric(vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      );

  IconData _fileIcon(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf'))  return Icons.picture_as_pdf_outlined;
    if (n.endsWith('.docx') || n.endsWith('.doc')) {
      return Icons.description_outlined;
    }
    if (n.endsWith('.xlsx') || n.endsWith('.xls')) {
      return Icons.table_chart_outlined;
    }
    if (RegExp(r'\.(jpg|jpeg|png|gif|webp)$').hasMatch(n)) {
      return Icons.image_outlined;
    }
    return Icons.attach_file;
  }
}

// ─── Widgets kecil ────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 9, color: color.withOpacity(0.9)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold)),
      );
}
