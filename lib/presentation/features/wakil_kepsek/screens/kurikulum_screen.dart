import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

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

  _PerangkatRow({
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

  factory _PerangkatRow.fromJson(Map<String, dynamic> json) {
    return _PerangkatRow(
      id: json['id'] ?? 0,
      guruId: json['guru_id'] as int?,
      namaGuru: json['nama_guru'] ??
          (json['guru_id'] != null ? 'Guru #${json['guru_id']}' : '—'),
      namaDokumen: json['nama_dokumen'] ?? json['nama_perangkat'] ?? '—',
      jenisDokumen: json['jenis_dokumen'] ?? json['jenis'] ?? '—',
      status: json['status'] ?? 'belum_lengkap',
      catatan: json['catatan'],
      namaFile: json['nama_file'],
      tanggalUpload: _fmtDate(json['created_at'] ?? json['tanggal_upload']),
    );
  }

  static String? _fmtDate(dynamic v) {
    if (v == null) return null;
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

// ─── Color helpers ────────────────────────────────────────────────────────────

const _jenisColor = {
  'RPP':     Color(0xFF2563EB),
  'Silabus': Color(0xFF16A34A),
  'Modul':   Color(0xFF7C3AED),
  'Prota':   Color(0xFFD97706),
  'Promes':  Color(0xFFEA580C),
};

Color _jenisClr(String jenis) => _jenisColor[jenis] ?? Colors.grey;

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

  // ── Filter state ──
  String _filterGuru   = '';
  String _filterJenis  = '';
  String _filterStatus = '';
  String _search       = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = sl<DioClient>();
      final resp = await dio.get(ApiEndpoints.learningDevices);
      final raw = resp.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map) {
        list = raw['data'] is List ? raw['data'] as List : [];
      }
      setState(() {
        _rows = list
            .map((e) => _PerangkatRow.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() { _error = 'Gagal memuat data perangkat pembelajaran'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  // ── Filtered list ──────────────────────────────────────────────────────────

  List<_PerangkatRow> get _filtered {
    return _rows.where((d) {
      if (_filterJenis.isNotEmpty && d.jenisDokumen != _filterJenis) {
        return false;
      }
      if (_filterStatus.isNotEmpty && d.status != _filterStatus) {
        return false;
      }
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
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  int get _totalLengkap  => _rows.where((d) => d.status == 'lengkap').length;
  int get _totalBelum    => _rows.where((d) => d.status != 'lengkap').length;
  int get _totalGuru     =>
      _rows.map((d) => d.guruId).where((id) => id != null).toSet().length;

  // ── Unique lists for filter dropdowns ─────────────────────────────────────

  List<String> get _jenisList =>
      _rows.map((d) => d.jenisDokumen).where((j) => j != '—').toSet().toList()
        ..sort();

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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          // ── Stats bar ───────────────────────────────────────────────────
          Container(
            color: const Color(0xFFEA580C),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _StatBox(label: 'Total Dokumen', value: '${_rows.length}',
                    color: Colors.white),
                const SizedBox(width: 6),
                _StatBox(label: 'Lengkap', value: '$_totalLengkap',
                    color: Colors.greenAccent),
                const SizedBox(width: 6),
                _StatBox(label: 'Belum Lengkap', value: '$_totalBelum',
                    color: Colors.redAccent),
                const SizedBox(width: 6),
                _StatBox(label: 'Guru', value: '$_totalGuru',
                    color: Colors.lightBlueAccent),
              ],
            ),
          ),

          // ── Filter panel ────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Nama Dokumen',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          prefixIcon:
                              const Icon(Icons.search, size: 18),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (v) =>
                            setState(() => _search = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Cari Guru',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        onChanged: (v) =>
                            setState(() => _filterGuru = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterJenis.isEmpty ? null : _filterJenis,
                        decoration: InputDecoration(
                          labelText: 'Jenis Dokumen',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: '',
                              child: Text('Semua Jenis')),
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
                        value:
                            _filterStatus.isEmpty ? null : _filterStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: '', child: Text('Semua Status')),
                          DropdownMenuItem(
                              value: 'lengkap', child: Text('Lengkap')),
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

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFEA580C)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 8),
                            Text(_error!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Coba Lagi')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.folder_open,
                                    size: 60, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  _rows.isEmpty
                                      ? 'Belum ada data perangkat pembelajaran'
                                      : 'Tidak ada yang sesuai filter',
                                  style: const TextStyle(
                                      color: Colors.grey),
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
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final doc = filtered[i];
                                final isLengkap =
                                    doc.status == 'lengkap';
                                final jenisColor =
                                    _jenisClr(doc.jenisDokumen);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E3A)
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border(
                                      left: BorderSide(
                                        color: isLengkap
                                            ? const Color(0xFF16A34A)
                                            : Colors.orange,
                                        width: 4,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header row
                                      Row(
                                        children: [
                                          // Jenis badge
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                            decoration: BoxDecoration(
                                              color: jenisColor
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              doc.jenisDokumen,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: jenisColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          // Status badge
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                            decoration: BoxDecoration(
                                              color: (isLengkap
                                                      ? Colors.green
                                                      : Colors.orange)
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: (isLengkap
                                                        ? Colors.green
                                                        : Colors.orange)
                                                    .withOpacity(0.4),
                                              ),
                                            ),
                                            child: Text(
                                              isLengkap
                                                  ? '✓ Lengkap'
                                                  : '⏳ Belum Lengkap',
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
                                      const SizedBox(height: 8),

                                      // Nama Dokumen
                                      Text(
                                        doc.namaDokumen,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),

                                      // Nama Guru + file info
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline,
                                              size: 13,
                                              color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              doc.namaGuru,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (doc.tanggalUpload != null) ...[
                                            const SizedBox(width: 8),
                                            const Icon(
                                                Icons.calendar_today,
                                                size: 11,
                                                color: Colors.grey),
                                            const SizedBox(width: 3),
                                            Text(
                                              doc.tanggalUpload!,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ],
                                      ),

                                      // Catatan (if any)
                                      if (doc.catatan != null &&
                                          doc.catatan!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.black12
                                                : Colors.grey.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.notes,
                                                  size: 12,
                                                  color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  doc.catatan!,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      // File info
                                      if (doc.namaFile != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              _fileIcon(doc.namaFile!),
                                              size: 13,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                doc.namaFile!,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                    fontStyle:
                                                        FontStyle.italic),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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

  IconData _fileIcon(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (ext.endsWith('.docx') || ext.endsWith('.doc')) {
      return Icons.description_outlined;
    }
    if (ext.endsWith('.xlsx') || ext.endsWith('.xls')) {
      return Icons.table_chart_outlined;
    }
    if (RegExp(r'\.(jpg|jpeg|png|gif|webp)$').hasMatch(ext)) {
      return Icons.image_outlined;
    }
    return Icons.attach_file;
  }
}

// ─── Reusable stat widget ─────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

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
}
