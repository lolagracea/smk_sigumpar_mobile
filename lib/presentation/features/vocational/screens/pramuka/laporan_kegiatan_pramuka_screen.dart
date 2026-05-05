import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../data/services/vocational_service.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/secure_storage.dart';
import '../../../../../core/constants/api_endpoints.dart';

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

  // Form – hanya gambar
  PlatformFile? _gambar;

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

  Future<void> _pickGambar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _gambar = result.files.first);
    }
  }

  Future<void> _simpan() async {
    if (_gambar == null) {
      _showSnack('Pilih gambar terlebih dahulu', Colors.red);
      return;
    }
    setState(() => _saving = true);
    try {
      final judul = _gambar!.name
          .replaceAll(RegExp(r'\.[^.]+$'), '')
          .replaceAll(RegExp(r'[_\-]+'), ' ');

      await _service.createLaporanKegiatan(
        judul: judul.isNotEmpty ? judul : 'Laporan Kegiatan',
        deskripsi: '',
        tanggal: _todayStr(),
        file: _gambar,
      );
      _showSnack('Laporan berhasil diupload!', Colors.green);
      setState(() => _gambar = null);
      _loadLaporan();
    } catch (_) {
      _showSnack('Gagal mengupload laporan', Colors.red);
    }
    setState(() => _saving = false);
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _hapus(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: Text('Hapus laporan "${item['judul'] ?? ''}"?'),
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

  void _lihatGambar(Map<String, dynamic> item) {
    final fileName = item['file_nama'] ?? '';
    final isImage = RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false)
        .hasMatch(fileName);
    if (!isImage) {
      _showSnack('File bukan gambar, gunakan tombol Unduh', Colors.orange);
      return;
    }
    final imageUrl =
        '${ApiEndpoints.baseUrl}/api/vocational/laporan-kegiatan/${item['id']}/download';
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ImageViewerScreen(
        imageUrl: imageUrl,
        judul: item['judul'] ?? 'Laporan',
        onDownload: () => _download(item),
      ),
    ));
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

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
            Text('Upload gambar laporan kegiatan pramuka',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[500])),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLaporan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Form Upload Gambar ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📸 Upload Gambar Laporan',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF374151))),
                    const SizedBox(height: 14),

                    // Preview gambar jika sudah dipilih
                    if (_gambar != null && _gambar!.bytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _gambar!.bytes!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _gambar!.name,
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark ? Colors.white54 : Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Area pilih gambar
                    GestureDetector(
                      onTap: _pickGambar,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF252836)
                              : const Color(0xFFF0F4FF),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3D4155)
                                : const Color(0xFF93C5FD),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _gambar != null
                                  ? Icons.image_outlined
                                  : Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF2563EB),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _gambar != null
                                  ? 'Ganti Gambar'
                                  : 'Tap untuk memilih gambar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Format: JPG, JPEG, PNG, WebP',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (_saving || _gambar == null) ? null : _simpan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? Colors.white12
                              : const Color(0xFFCBD5E1),
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          _saving ? 'Mengupload...' : '⬆  Upload Gambar',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Daftar Laporan ──
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('🖼 Daftar Foto Laporan',
                                style: TextStyle(
                                    fontSize: 14,
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
                            child: Text('${_laporan.length} FOTO',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[500])),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                        color: isDark ? Colors.white12 : borderColor,
                        height: 1),
                    if (_loading)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()))
                    else if (_laporan.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(children: [
                            const Text('🖼', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 8),
                            Text('Belum ada foto yang diupload',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[400])),
                          ]),
                        ),
                      )
                    else
                      _buildImageGrid(isDark, borderColor),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(bool isDark, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.80,
        ),
        itemCount: _laporan.length,
        itemBuilder: (context, i) {
          final item = _laporan[i];
          final fileName = item['file_nama'] ?? '';
          final isImage = RegExp(
                  r'\.(jpg|jpeg|png|gif|webp)$',
                  caseSensitive: false)
              .hasMatch(fileName);
          final imageUrl = isImage
              ? '${ApiEndpoints.baseUrl}/api/vocational/laporan-kegiatan/${item['id']}/download'
              : null;

          return Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF252836)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF3D4155)
                      : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Expanded(
                  child: GestureDetector(
                    onTap: isImage ? () => _lihatGambar(item) : null,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      child: isImage && imageUrl != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholder(isDark),
                                  loadingBuilder:
                                      (_, child, progress) {
                                    if (progress == null) return child;
                                    return Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            value: progress.expectedTotalBytes !=
                                                    null
                                                ? progress.cumulativeBytesLoaded /
                                                    progress.expectedTotalBytes!
                                                : null));
                                  },
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.zoom_in,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            )
                          : _placeholder(isDark),
                    ),
                  ),
                ),

                // Info & aksi
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['judul'] ?? '-',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['tanggal'] ?? '-',
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey[400]),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (isImage) ...[
                            Expanded(
                              child: _SmallBtn(
                                label: '👁 Lihat',
                                color: const Color(0xFF1D4ED8),
                                bg: const Color(0xFFEFF6FF),
                                onTap: () => _lihatGambar(item),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: _SmallBtn(
                              label: '⬇ Unduh',
                              color: const Color(0xFF16A34A),
                              bg: const Color(0xFFDCFCE7),
                              onTap: () => _download(item),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _SmallBtn(
                            label: '🗑',
                            color: const Color(0xFFDC2626),
                            bg: const Color(0xFFFFEBEB),
                            onTap: () => _hapus(item),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder(bool isDark) => Container(
        color: isDark ? const Color(0xFF1A1D27) : const Color(0xFFF1F5F9),
        child: Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 32,
              color: isDark ? Colors.white24 : Colors.grey[300]),
        ),
      );
}

// ─── Full Screen Image Viewer ─────────────────────────────────────────────────

class _ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String judul;
  final VoidCallback onDownload;

  const _ImageViewerScreen({
    required this.imageUrl,
    required this.judul,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(judul,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download',
            onPressed: () {
              onDownload();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 5,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined,
                    size: 64, color: Colors.white38),
                SizedBox(height: 12),
                Text('Gagal memuat gambar',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Small Button ─────────────────────────────────────────────────────────────

class _SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _SmallBtn(
      {required this.label,
      required this.color,
      required this.bg,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
      ),
    );
  }
}
