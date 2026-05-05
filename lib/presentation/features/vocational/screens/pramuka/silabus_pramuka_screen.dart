import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../data/services/vocational_service.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/secure_storage.dart';

class SilabusPramukaScreen extends StatefulWidget {
  const SilabusPramukaScreen({super.key});

  @override
  State<SilabusPramukaScreen> createState() => _SilabusPramukaScreenState();
}

class _SilabusPramukaScreenState extends State<SilabusPramukaScreen> {
  late final VocationalService _service;

  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _silabusList = [];
  bool _loading = false;
  bool _uploading = false;

  String _filterKelasId = '';

  // Form state
  String _kelasId = '';
  String _namaKelas = '';
  String _judulKegiatan = '';
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
    _loadKelas();
    _loadSilabus();
  }

  Future<void> _loadKelas() async {
    try {
      final res = await _service.getRawKelasVokasi();
      setState(() => _kelasList = List<Map<String, dynamic>>.from(res['data'] ?? []));
    } catch (_) {}
  }

  Future<void> _loadSilabus() async {
    setState(() => _loading = true);
    try {
      final res = await _service.getRawSilabus();
      setState(() => _silabusList = List<Map<String, dynamic>>.from(res['data'] ?? []));
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
    if (_kelasId.isEmpty) {
      _showSnack('Pilih kelas terlebih dahulu', Colors.red);
      return;
    }
    if (_judulKegiatan.trim().isEmpty) {
      _showSnack('Judul kegiatan wajib diisi', Colors.red);
      return;
    }
    setState(() => _uploading = true);
    try {
      await _service.createSilabus(
        kelasId: _kelasId,
        namaKelas: _namaKelas,
        judulKegiatan: _judulKegiatan.trim(),
        tanggal: _tanggal,
        file: _file,
      );
      _showSnack('Silabus berhasil disimpan!', Colors.green);
      setState(() {
        _kelasId = '';
        _namaKelas = '';
        _judulKegiatan = '';
        _file = null;
      });
      _loadSilabus();
    } catch (e) {
      _showSnack('Gagal menyimpan silabus', Colors.red);
    }
    setState(() => _uploading = false);
  }

  Future<void> _hapus(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Silabus'),
        content: Text('Hapus "${item['judul_kegiatan']}"?'),
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
      await _service.deleteSilabus(item['id']);
      _showSnack('Silabus berhasil dihapus', Colors.green);
      _loadSilabus();
    } catch (_) {
      _showSnack('Gagal menghapus', Colors.red);
    }
  }

  Future<void> _download(Map<String, dynamic> item) async {
    try {
      await _service.downloadFile(
        url: '/api/vocational/silabus/${item['id']}/download',
        fileName: item['file_nama'] ?? 'silabus',
      );
    } catch (_) {
      _showSnack('Gagal mengunduh file', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterKelasId.isEmpty) return _silabusList;
    return _silabusList.where((e) => e['kelas_id'].toString() == _filterKelasId).toList();
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
            Text('Silabus & Perangkat Kegiatan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            Text('Upload dan kelola dokumen silabus pramuka',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500])),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSilabus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Form Tambah ──
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
                    Text('📤 Tambah Silabus Baru',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF374151))),
                    const SizedBox(height: 14),

                    // Kelas
                    _lbl('Kelas', isDark),
                    const SizedBox(height: 6),
                    _dropdownKelas(isDark, borderColor),
                    const SizedBox(height: 12),

                    // Judul
                    _lbl('Judul Kegiatan', isDark),
                    const SizedBox(height: 6),
                    TextField(
                      style: _txtStyle(isDark),
                      decoration: _deco('Contoh: Silabus Kepramukaan Semester 1', isDark),
                      onChanged: (v) => setState(() => _judulKegiatan = v),
                    ),
                    const SizedBox(height: 12),

                    // Tanggal
                    _lbl('Tanggal', isDark),
                    const SizedBox(height: 6),
                    _dateField(isDark, borderColor),
                    const SizedBox(height: 12),

                    // File
                    _lbl('File (PDF/DOCX/Gambar)', isDark),
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
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
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
                        onPressed: _uploading ? null : _simpan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(_uploading ? 'Menyimpan...' : '⬆  Simpan Silabus',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Daftar Silabus ──
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
                            child: Text('📁 Daftar Silabus Terupload',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF374151))),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF252836) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${_filtered.length} FILE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.grey[500])),
                          ),
                        ],
                      ),
                    ),

                    // Filter kelas
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filterKelasId.isEmpty ? null : _filterKelasId,
                            isExpanded: true,
                            hint: Text('Semua Kelas', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[400])),
                            dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                            items: [
                              DropdownMenuItem(value: '', child: Text('Semua Kelas', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500]))),
                              ..._kelasList.map((k) => DropdownMenuItem(value: k['id'].toString(), child: Text(k['nama_kelas'] ?? '-'))),
                            ],
                            onChanged: (v) => setState(() => _filterKelasId = v ?? ''),
                          ),
                        ),
                      ),
                    ),

                    Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), height: 1),

                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              const Text('📁', style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 8),
                              Text('Belum ada silabus yang diupload',
                                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400])),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), height: 1),
                        itemBuilder: (context, i) {
                          final item = _filtered[i];
                          return Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item['nama_kelas'] ?? '-',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['judul_kegiatan'] ?? '-',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['tanggal']?.toString().substring(0, 10) ?? '-'}  •  ${item['file_nama'] ?? '—'}',
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

  Widget _dropdownKelas(bool isDark, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _kelasId.isEmpty ? null : _kelasId,
          isExpanded: true,
          hint: Text('-- Pilih Kelas --', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[400])),
          dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B)),
          items: _kelasList.map((k) => DropdownMenuItem(value: k['id'].toString(), child: Text(k['nama_kelas'] ?? '-'))).toList(),
          onChanged: (v) {
            final kelas = _kelasList.firstWhere((e) => e['id'].toString() == v, orElse: () => {});
            setState(() {
              _kelasId = v ?? '';
              _namaKelas = kelas['nama_kelas'] ?? '';
            });
          },
        ),
      ),
    );
  }

  Widget _dateField(bool isDark, Color border) {
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
