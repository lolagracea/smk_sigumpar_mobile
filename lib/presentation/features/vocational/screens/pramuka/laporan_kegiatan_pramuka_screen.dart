import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../data/services/vocational_service.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/secure_storage.dart';

class LaporanKegiatanPramukaScreen extends StatefulWidget {
  const LaporanKegiatanPramukaScreen({super.key});

  @override
  State<LaporanKegiatanPramukaScreen> createState() => _LaporanKegiatanPramukaScreenState();
}

class _LaporanKegiatanPramukaScreenState extends State<LaporanKegiatanPramukaScreen> {
  late final VocationalService _service;

  List<Map<String, dynamic>> _laporan = [];
  bool _loading = false;
  bool _saving = false;

  // Form
  String _judul = '';
  String _deskripsi = '';
  String _tanggal = _todayStr();
  PlatformFile? _file;

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _service = VocationalService(dioClient: DioClient(secureStorage: sl<SecureStorage>()));
    _loadLaporan();
  }

  Future<void> _loadLaporan() async {
    setState(() => _loading = true);
    try {
      final res = await _service.getRawLaporanKegiatan();
      setState(() => _laporan = List<Map<String, dynamic>>.from(res['data'] ?? []));
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'jpg', 'jpeg', 'png'],
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D3142) : const Color(0xFFE2E8F0);
    final bgColor = isDark ? const Color(0xFF0F1117) : const Color(0xFFF8F9FC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1D27) : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Laporan Kegiatan Pramuka',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            Text('Upload, lihat, dan kelola laporan kegiatan pramuka',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500])),
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
              // ── Form ──
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
                    Text('📤 Tambah Laporan Baru',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF374151))),
                    const SizedBox(height: 14),

                    _lbl('Judul Laporan', isDark),
                    const SizedBox(height: 6),
                    TextField(
                      style: _txtStyle(isDark),
                      decoration: _deco('Contoh: Laporan Kegiatan Pramuka Bulan Januari', isDark),
                      onChanged: (v) => setState(() => _judul = v),
                    ),
                    const SizedBox(height: 12),

                    _lbl('Tanggal', isDark),
                    const SizedBox(height: 6),
                    _dateField(isDark),
                    const SizedBox(height: 12),

                    _lbl('Deskripsi', isDark),
                    const SizedBox(height: 6),
                    TextField(
                      maxLines: 3,
                      style: _txtStyle(isDark),
                      decoration: _deco('Deskripsi singkat kegiatan...', isDark),
                      onChanged: (v) => setState(() => _deskripsi = v),
                    ),
                    const SizedBox(height: 12),

                    _lbl('File Laporan (PDF/DOCX/Gambar)', isDark),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252836) : Colors.white,
                          border: Border.all(color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                              child: const Text('Pilih File', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _file?.name ?? 'Belum ada file dipilih',
                                style: TextStyle(fontSize: 12, color: _file != null ? (isDark ? Colors.white70 : const Color(0xFF374151)) : (isDark ? Colors.white38 : Colors.grey[400])),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _simpan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(_saving ? 'Menyimpan...' : '⬆  Simpan Laporan',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Daftar ──
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
                            child: Text('📁 Daftar Laporan Kegiatan',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF374151))),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF252836) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                            child: Text('${_laporan.length} FILE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.grey[500])),
                          ),
                        ],
                      ),
                    ),

                    Divider(color: isDark ? Colors.white12 : borderColor, height: 1),

                    if (_loading)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
                    else if (_laporan.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(children: [
                            const Text('📁', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 8),
                            Text('Belum ada laporan yang diupload', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400])),
                          ]),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _laporan.length,
                        separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white12 : borderColor, height: 1),
                        itemBuilder: (context, i) {
                          final item = _laporan[i];
                          return Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['judul'] ?? '-',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 4),
                                if ((item['deskripsi'] ?? '').toString().isNotEmpty)
                                  Text(
                                    item['deskripsi'].toString(),
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[500]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['tanggal'] ?? '-'}  •  ${item['file_nama'] ?? '—'}',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[400]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (item['file_nama'] != null) ...[
                                      _ActionBtn(
                                        label: '⬇ Unduh',
                                        color: const Color(0xFF16A34A),
                                        bg: const Color(0xFFDCFCE7),
                                        onTap: () => _download(item),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    _ActionBtn(
                                      label: '🗑 Hapus',
                                      color: const Color(0xFFDC2626),
                                      bg: const Color(0xFFFFEBEB),
                                      onTap: () => _hapus(item),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
          setState(() => _tanggal = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          border: Border.all(color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? Colors.white38 : Colors.grey[400]),
            const SizedBox(width: 8),
            Text(_tanggal, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _lbl(String text, bool isDark) => Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: isDark ? Colors.white38 : Colors.grey[500]),
      );

  TextStyle _txtStyle(bool isDark) => TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87);

  InputDecoration _deco(String hint, bool isDark) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[400]),
        filled: true,
        fillColor: isDark ? const Color(0xFF252836) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}
