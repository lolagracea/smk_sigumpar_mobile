import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../data/services/vocational_service.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/secure_storage.dart';
import '../../../../../core/constants/api_endpoints.dart';

bool _isImage(String? fileName) =>
    fileName != null &&
    RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false)
        .hasMatch(fileName);

class LaporanKegiatanPramukaScreen extends StatefulWidget {
  const LaporanKegiatanPramukaScreen({super.key});

  @override
  State<LaporanKegiatanPramukaScreen> createState() =>
      _LaporanKegiatanPramukaScreenState();
}

class _LaporanKegiatanPramukaScreenState
    extends State<LaporanKegiatanPramukaScreen> {
  late final VocationalService _service;

  List<Map<String, dynamic>> _laporan = [];
  bool _loading = false;
  bool _saving = false;

  // Form fields – sama seperti web
  String _judul = '';
  String _deskripsi = '';
  String _tanggal = _todayStr();
  PlatformFile? _file;

  // Preview / download modal
  Map<String, dynamic>? _previewDoc;

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _service = VocationalService(
        dioClient: DioClient(secureStorage: sl<SecureStorage>()));
    _loadLaporan();
  }

  Future<void> _loadLaporan() async {
    setState(() => _loading = true);
    try {
      final res = await _service.getRawLaporanKegiatan();
      setState(() =>
          _laporan = List<Map<String, dynamic>>.from(res['data'] ?? []));
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.first);
    }
  }

  Future<void> _simpan() async {
    if (_judul.trim().isEmpty) {
      _showSnack('Judul laporan wajib diisi', Colors.red);
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.createLaporanKegiatan(
        judul: _judul.trim(),
        deskripsi: _deskripsi,
        tanggal: _tanggal,
        file: _file,
      );
      _showSnack('Laporan berhasil disimpan!', Colors.green);
      setState(() {
        _judul = '';
        _deskripsi = '';
        _tanggal = _todayStr();
        _file = null;
      });
      _loadLaporan();
    } catch (_) {
      _showSnack('Gagal menyimpan laporan', Colors.red);
    }
    setState(() => _saving = false);
  }

  Future<void> _hapus(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: Text('Hapus laporan "${item['judul']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteLaporanKegiatan(item['id']);
      _showSnack('Laporan berhasil dihapus', Colors.green);
      _loadLaporan();
    } catch (_) {
      _showSnack('Gagal menghapus', Colors.red);
    }
  }

  Future<void> _download(Map<String, dynamic> item) async {
    try {
      await _service.downloadFile(
        url: '/api/vocational/laporan-kegiatan/${item['id']}/download',
        fileName: item['file_nama'] ?? 'laporan',
      );
    } catch (_) {
      _showSnack('Gagal mengunduh file', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ── Image URL helper ──────────────────────────────────────────────────────
  String _imageUrl(Map<String, dynamic> item) =>
      '${ApiEndpoints.baseUrl}/api/vocational/laporan-kegiatan/${item['id']}/download';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2D3142) : const Color(0xFFE2E8F0);
    final bgColor =
        isDark ? const Color(0xFF0F1117) : const Color(0xFFF8F9FC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1D27) : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Laporan Kegiatan Pramuka',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
            Text('Upload, lihat, dan kelola laporan kegiatan pramuka',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[500])),
          ],
        ),
      ),

      // ── Preview Modal overlay ──────────────────────────────────────────────
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadLaporan,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Form ──
                  _buildForm(isDark, cardColor, borderColor),
                  const SizedBox(height: 16),
                  // ── Tabel ──
                  _buildTable(isDark, cardColor, borderColor),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Modal preview gambar / dokumen
          if (_previewDoc != null)
            _PreviewModal(
              item: _previewDoc!,
              imageUrl: _isImage(_previewDoc!['file_nama'])
                  ? _imageUrl(_previewDoc!)
                  : null,
              onDownload: () => _download(_previewDoc!),
              onClose: () => setState(() => _previewDoc = null),
            ),
        ],
      ),
    );
  }

  // ── Form Card ──────────────────────────────────────────────────────────────
  Widget _buildForm(bool isDark, Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📤 Tambah Laporan Baru',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF374151))),
          const SizedBox(height: 16),

          // Judul
          _lbl('Judul Laporan', isDark),
          const SizedBox(height: 6),
          _textField(
            hint: 'Contoh: Laporan Kegiatan Pramuka Bulan Januari',
            isDark: isDark,
            value: _judul,
            onChanged: (v) => setState(() => _judul = v),
          ),
          const SizedBox(height: 12),

          // Tanggal
          _lbl('Tanggal', isDark),
          const SizedBox(height: 6),
          _dateField(isDark),
          const SizedBox(height: 12),

          // Deskripsi
          _lbl('Deskripsi', isDark),
          const SizedBox(height: 6),
          _textField(
            hint: 'Deskripsi singkat kegiatan...',
            isDark: isDark,
            maxLines: 3,
            value: _deskripsi,
            onChanged: (v) => setState(() => _deskripsi = v),
          ),
          const SizedBox(height: 12),

          // File
          _lbl('File Laporan (PDF / DOCX / Gambar)', isDark),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF252836) : Colors.white,
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF3D4155)
                        : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('Pilih File',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _file?.name ?? 'Belum ada file dipilih',
                      style: TextStyle(
                          fontSize: 12,
                          color: _file != null
                              ? (isDark
                                  ? Colors.white70
                                  : const Color(0xFF374151))
                              : (isDark
                                  ? Colors.white38
                                  : Colors.grey[400])),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Simpan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _saving ? 'Menyimpan...' : '⬆  Simpan Laporan',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabel Daftar ──────────────────────────────────────────────────────────
  Widget _buildTable(bool isDark, Color cardColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text('📁 Daftar Laporan Kegiatan',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF374151))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF252836)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${_laporan.length} FILE',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white38 : Colors.grey[500])),
                ),
              ],
            ),
          ),
          Divider(color: isDark ? Colors.white12 : borderColor, height: 1),

          // Thead
          Container(
            color: isDark ? const Color(0xFF151720) : const Color(0xFFF9FAFB),
            child: Row(
              children: [
                _th('JUDUL', flex: 3, isDark: isDark),
                _th('TANGGAL', flex: 2, isDark: isDark),
                _th('FILE', flex: 2, isDark: isDark),
                _th('AKSI', flex: 3, isDark: isDark, center: true),
              ],
            ),
          ),
          Divider(color: isDark ? Colors.white12 : borderColor, height: 1),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_laporan.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(children: [
                  const Text('📁', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text('Belum ada laporan yang diupload',
                      style: TextStyle(
                          color: isDark
                              ? Colors.white38
                              : Colors.grey[400])),
                ]),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _laporan.length,
              separatorBuilder: (_, __) => Divider(
                  color: isDark ? Colors.white12 : borderColor, height: 1),
              itemBuilder: (_, i) => _buildRow(_laporan[i], isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> item, bool isDark) {
    final fileName = item['file_nama'] as String?;
    final isImg = _isImage(fileName);

    return InkWell(
      onTap: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul + deskripsi
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['judul'] ?? '-',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  if ((item['deskripsi'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(item['deskripsi'].toString(),
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.grey[500]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Tanggal
            Expanded(
              flex: 2,
              child: Text(item['tanggal'] ?? '-',
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? Colors.white54 : Colors.grey[500])),
            ),

            // Nama file (klik → lihat foto jika gambar)
            Expanded(
              flex: 2,
              child: fileName == null
                  ? Text('—',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white24 : Colors.grey[300]))
                  : isImg
                      ? GestureDetector(
                          onTap: () =>
                              setState(() => _previewDoc = item),
                          child: Row(
                            children: [
                              const Text('🖼️ ',
                                  style: TextStyle(fontSize: 11)),
                              Expanded(
                                child: Text(fileName,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2563EB)),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        )
                      : Text(fileName,
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey[400]),
                          overflow: TextOverflow.ellipsis),
            ),

            // Aksi
            Expanded(
              flex: 3,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  if (fileName != null) ...[
                    _AksiBtn(
                      label: '👁 Lihat',
                      color: const Color(0xFF2563EB),
                      bg: const Color(0xFFEFF6FF),
                      onTap: () => setState(() => _previewDoc = item),
                    ),
                    _AksiBtn(
                      label: '⬇ Unduh',
                      color: const Color(0xFF16A34A),
                      bg: const Color(0xFFDCFCE7),
                      onTap: () => _download(item),
                    ),
                  ],
                  _AksiBtn(
                    label: '🗑 Hapus',
                    color: const Color(0xFFDC2626),
                    bg: const Color(0xFFFFEBEB),
                    onTap: () => _hapus(item),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _th(String label,
      {required int flex, required bool isDark, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(label,
            textAlign: center ? TextAlign.center : TextAlign.left,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? Colors.white38 : Colors.grey[500])),
      ),
    );
  }

  Widget _lbl(String text, bool isDark) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? Colors.white38 : Colors.grey[500]),
      );

  Widget _textField({
    required String hint,
    required bool isDark,
    required String value,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: value,
      maxLines: maxLines,
      style: TextStyle(
          fontSize: 13, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : Colors.grey[400]),
        filled: true,
        fillColor: isDark ? const Color(0xFF252836) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3D4155)
                    : const Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3D4155)
                    : const Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _dateField(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(_tanggal) ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setState(() => _tanggal =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          border: Border.all(
              color: isDark
                  ? const Color(0xFF3D4155)
                  : const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14,
                color: isDark ? Colors.white38 : Colors.grey[400]),
            const SizedBox(width: 8),
            Text(_tanggal,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }
}

// ─── Preview Modal (gambar fullscreen + download) ─────────────────────────────

class _PreviewModal extends StatelessWidget {
  final Map<String, dynamic> item;
  final String? imageUrl;
  final VoidCallback onDownload;
  final VoidCallback onClose;

  const _PreviewModal({
    required this.item,
    required this.imageUrl,
    required this.onDownload,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // block tap-through
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24)
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['judul'] ?? '-',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B))),
                              if ((item['file_nama'] ?? '').toString().isNotEmpty)
                                Text(item['file_nama'].toString(),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Download btn
                        TextButton.icon(
                          onPressed: () {
                            onDownload();
                            onClose();
                          },
                          icon: const Icon(Icons.download_outlined, size: 16),
                          label: const Text('Unduh',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            backgroundColor: const Color(0xFFDCFCE7),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Tutup btn
                        TextButton(
                          onPressed: onClose,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            backgroundColor: const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('✕ Tutup',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Konten gambar
                  Flexible(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20)),
                      child: Container(
                        color: const Color(0xFFF8FAFC),
                        constraints: const BoxConstraints(minHeight: 300),
                        child: imageUrl != null
                            ? InteractiveViewer(
                                panEnabled: true,
                                minScale: 0.5,
                                maxScale: 5,
                                child: Image.network(
                                  imageUrl!,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: progress.expectedTotalBytes !=
                                                null
                                            ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image_outlined,
                                            size: 48, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Gagal memuat gambar',
                                            style: TextStyle(
                                                color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Text('📄',
                                          style: TextStyle(fontSize: 56)),
                                      const SizedBox(height: 12),
                                      Text(
                                          item['file_nama']?.toString() ??
                                              '-',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF374151))),
                                      const SizedBox(height: 6),
                                      const Text(
                                          'Format ini tidak dapat\nditampilkan langsung',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          onDownload();
                                          onClose();
                                        },
                                        icon: const Icon(
                                            Icons.download_outlined,
                                            size: 16),
                                        label: const Text(
                                            '⬇ Download untuk Membuka',
                                            style:
                                                TextStyle(fontSize: 13)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 18,
                                                  vertical: 10),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Aksi Button ──────────────────────────────────────────────────────────────

class _AksiBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _AksiBtn(
      {required this.label,
      required this.color,
      required this.bg,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}
