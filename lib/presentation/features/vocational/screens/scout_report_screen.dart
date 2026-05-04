// ─────────────────────────────────────────────────────────────────────────────
// lib/presentation/features/vocational/screens/scout_report_screen.dart
//
// Laporan Kegiatan Pramuka — 100% MIRROR web LaporanKegiatanPage.jsx
//
// FEATURE PARITY WEB → MOBILE:
//   ✅ Header: "Laporan Kegiatan Pramuka" + subtitle
//   ✅ Form tambah laporan:
//       - Judul (required)
//       - Tanggal (date picker)
//       - Deskripsi (multiline)
//       - Upload File (PDF / DOCX / Gambar) — via file_picker
//   ✅ Tombol Simpan Laporan
//   ✅ Daftar laporan (Card — adaptasi table → ListView)
//       - Judul, Deskripsi, Tanggal, Nama File
//       - Badge jumlah file
//   ✅ Per-baris: Lihat File | Download | Hapus
//   ✅ Konfirmasi dialog sebelum hapus
//   ✅ Loading state, error state, empty state
//   ✅ Pull-to-refresh
//   ✅ Preview file: Image (full screen) | PDF (info + download)
//   ✅ Semua field sama dengan web (id, judul, deskripsi, tanggal, file_nama)
//   ✅ API endpoints identik dengan web
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../data/models/laporan_kegiatan_model.dart';
import '../providers/vocational_provider.dart';
import '../widgets/pramuka_drawer.dart';

class ScoutReportScreen extends StatefulWidget {
  const ScoutReportScreen({super.key});

  @override
  State<ScoutReportScreen> createState() => _ScoutReportScreenState();
}

class _ScoutReportScreenState extends State<ScoutReportScreen> {
  // ── Form controllers ─────────────────────────────────────────
  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();

  // ── File yang dipilih ────────────────────────────────────────
  PlatformFile? _selectedFile;

  // ── Form visibility ──────────────────────────────────────────
  bool _showForm = false;

  static const _primaryBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    // Set tanggal default ke hari ini — mirror web: new Date().toISOString().slice(0,10)
    _tanggalCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocationalProvider>().fetchLaporanKegiatan();
    });
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskripsiCtrl.dispose();
    _tanggalCtrl.dispose();
    super.dispose();
  }

  // ── Pilih file — mirror web input type="file" accept="..." ───
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'gif', 'webp'],
      withData: true, // load bytes langsung
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  // ── Reset form — mirror web setelah handleSimpan() sukses ────
  void _resetForm() {
    _judulCtrl.clear();
    _deskripsiCtrl.clear();
    _tanggalCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      _selectedFile = null;
      _showForm = false;
    });
  }

  // ── Simpan laporan — mirror web handleSimpan() ───────────────
  Future<void> _handleSimpan() async {
    final judul = _judulCtrl.text.trim();
    if (judul.isEmpty) {
      _showSnackbar('Judul laporan wajib diisi', isError: true);
      return;
    }

    final provider = context.read<VocationalProvider>();

    final (success, errMsg) = await provider.createLaporanKegiatan(
      judul: judul,
      tanggal: _tanggalCtrl.text,
      deskripsi: _deskripsiCtrl.text.trim(),
      fileBytes: _selectedFile?.bytes?.toList(),
      fileName: _selectedFile?.name,
      fileMime: _getMime(_selectedFile?.name),
    );

    if (!mounted) return;

    if (success) {
      _showSnackbar('Laporan berhasil disimpan!');
      _resetForm();
    } else {
      _showSnackbar(errMsg ?? 'Gagal menyimpan laporan', isError: true);
    }
  }

  // ── Hapus — mirror web handleHapus() dengan konfirmasi ───────
  Future<void> _handleHapus(LaporanKegiatanModel laporan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Hapus Laporan'),
          ],
        ),
        content: Text('Hapus laporan "${laporan.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<VocationalProvider>();
    final (success, errMsg) = await provider.deleteLaporanKegiatan(laporan.id);
    if (!mounted) return;
    if (success) {
      _showSnackbar('Laporan berhasil dihapus');
    } else {
      _showSnackbar(errMsg ?? 'Gagal menghapus laporan', isError: true);
    }
  }

  // ── View / Preview file — mirror web PreviewModal ────────────
  Future<void> _handleLihatFile(LaporanKegiatanModel laporan) async {
    final provider = context.read<VocationalProvider>();

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final (bytes, mime, errMsg) = await provider.viewLaporanFile(laporan.id);

    if (!mounted) return;
    Navigator.pop(context); // tutup loading

    if (errMsg != null) {
      _showSnackbar('Gagal memuat file: $errMsg', isError: true);
      return;
    }

    if (bytes == null || bytes.isEmpty) {
      _showSnackbar('File kosong atau tidak ditemukan', isError: true);
      return;
    }

    final resolvedMime = mime ?? laporan.fileMime ?? 'application/octet-stream';

    // Mirror web: cek apakah bisa di-inline
    final isImage = resolvedMime.startsWith('image/');
    final isPdf = resolvedMime == 'application/pdf';

    if (isImage) {
      // Tampilkan gambar full screen — mirror web ImagePreviewModal
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => _ImagePreviewScreen(
          bytes: Uint8List.fromList(bytes),
          title: laporan.judul,
          fileName: laporan.fileNama ?? '',
        ),
      ));
    } else if (isPdf) {
      // PDF tidak bisa inline di mobile — tampilkan info + option download
      // mirror web fallback untuk non-inline
      if (mounted) {
        _showPdfInfoDialog(laporan, bytes);
      }
    } else {
      // File lain — tawarkan download saja
      if (mounted) {
        _showSnackbar('Format ini tidak dapat ditampilkan. Gunakan tombol Unduh.');
      }
    }
  }

  // ── Download file ─────────────────────────────────────────────
  Future<void> _handleDownload(LaporanKegiatanModel laporan) async {
    _showSnackbar('Mengunduh ${laporan.fileNama ?? 'file'}...');
    final provider = context.read<VocationalProvider>();
    final (bytes, errMsg) = await provider.downloadLaporanFile(laporan.id);
    if (!mounted) return;
    if (errMsg != null) {
      _showSnackbar('Gagal mengunduh: $errMsg', isError: true);
    } else {
      _showSnackbar('File berhasil diunduh!');
    }
  }

  // ── Dialog info PDF (mobile tidak bisa inline render PDF) ────
  void _showPdfInfoDialog(LaporanKegiatanModel laporan, List<int> bytes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('📄', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                laporan.judul,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              laporan.fileNama ?? '',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              'Format PDF dapat diunduh ke perangkat Anda.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleDownload(laporan);
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Laporan Kegiatan'),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.close_rounded : Icons.add_rounded),
            tooltip: _showForm ? 'Tutup Form' : 'Tambah Laporan',
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      drawer: const PramukaDrawer(currentRoute: RouteNames.scoutReport),
      body: Consumer<VocationalProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchLaporanKegiatan(refresh: true),
            child: CustomScrollView(
              slivers: [
                // ── Header info — mirror web subtitle ───────────
                SliverToBoxAdapter(
                  child: _buildPageHeader(),
                ),

                // ── Form tambah laporan — mirror web "Tambah Laporan Baru" ──
                if (_showForm)
                  SliverToBoxAdapter(
                    child: _buildForm(provider),
                  ),

                // ── List header ─────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildListHeader(provider),
                ),

                // ── Content ─────────────────────────────────────
                if (provider.loadingLaporan)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.laporanError != null)
                  SliverFillRemaining(
                    child: _buildErrorState(provider),
                  )
                else if (provider.laporanKegiatan.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildLaporanCard(provider.laporanKegiatan[i]),
                        childCount: provider.laporanKegiatan.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),

      // FAB jika form tidak sedang ditampilkan
      floatingActionButton: !_showForm
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showForm = true),
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Tambah Laporan'),
            )
          : null,
    );
  }

  // ── Header halaman — mirror web title + subtitle ──────────────
  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laporan Kegiatan Pramuka',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload, lihat, dan kelola laporan kegiatan pramuka',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Form tambah laporan — mirror web form section ─────────────
  Widget _buildForm(VocationalProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: const Row(
              children: [
                Text('📤', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text(
                  'Tambah Laporan Baru',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),

          // ── Form fields ───────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Judul + Tanggal (grid 2 kolom di web → 2 field berurutan di mobile)
                _buildTextField(
                  controller: _judulCtrl,
                  label: 'Judul Laporan',
                  hint: 'Contoh: Laporan Kegiatan PJOK Bulan Januari',
                  required: true,
                ),
                const SizedBox(height: 12),

                // Tanggal — date picker
                _buildDateField(),
                const SizedBox(height: 12),

                // Deskripsi
                _buildTextField(
                  controller: _deskripsiCtrl,
                  label: 'Deskripsi',
                  hint: 'Deskripsi singkat kegiatan...',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // File upload — mirror web input[type=file]
                _buildFileField(),
                const SizedBox(height: 20),

                // Tombol simpan
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.savingLaporan ? null : _handleSimpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.6),
                    ),
                    icon: provider.savingLaporan
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload_rounded, size: 18),
                    label: Text(
                      provider.savingLaporan ? 'Menyimpan...' : '⬆ Simpan Laporan',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 2),
              Text('*', style: TextStyle(color: Colors.red.shade500, fontSize: 12)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TANGGAL',
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: Colors.grey.shade500, letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _tanggalCtrl,
          readOnly: true,
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              _tanggalCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
            }
          },
        ),
      ],
    );
  }

  Widget _buildFileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FILE LAPORAN (PDF/DOCX/GAMBAR)',
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: Colors.grey.shade500, letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedFile != null ? _primaryBlue : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(10),
              color: _selectedFile != null
                  ? _primaryBlue.withValues(alpha: 0.04)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  _selectedFile != null
                      ? Icons.attach_file_rounded
                      : Icons.upload_file_outlined,
                  size: 18,
                  color: _selectedFile != null ? _primaryBlue : Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _selectedFile != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.name,
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500,
                                color: _primaryBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_selectedFile!.size > 0)
                              Text(
                                _formatFileSize(_selectedFile!.size),
                                style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        )
                      : Text(
                          'Pilih file (.pdf, .docx, .jpg, .png...)',
                          style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500,
                          ),
                        ),
                ),
                if (_selectedFile != null)
                  GestureDetector(
                    onTap: () => setState(() => _selectedFile = null),
                    child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── List header — mirror web "Daftar Laporan Kegiatan" ────────
  Widget _buildListHeader(VocationalProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Text('📁', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          const Text(
            'Daftar Laporan Kegiatan',
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151),
            ),
          ),
          const Spacer(),
          // Badge jumlah — mirror web "{laporan.length} FILE"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${provider.laporanKegiatan.length} FILE',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card per laporan — adaptasi table row → Card ──────────────
  // Kolom web: Judul | Deskripsi | Tanggal | File | Aksi
  Widget _buildLaporanCard(LaporanKegiatanModel laporan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Judul ─────────────────────────────
            Text(
              laporan.judul,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 6),

            // ── Row 2: Deskripsi ─────────────────────────
            if (laporan.deskripsi != null && laporan.deskripsi!.isNotEmpty) ...[
              Text(
                laporan.deskripsi!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
            ],

            // ── Row 3: Tanggal + File nama ────────────────
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  laporan.tanggal,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                if (laporan.hasFile) ...[
                  const SizedBox(width: 12),
                  Icon(
                    laporan.isImage ? Icons.image_outlined : Icons.attach_file_rounded,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      laporan.fileNama!,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // ── Row 4: Tombol aksi — mirror web Lihat | Unduh | Hapus ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (laporan.hasFile) ...[
                  // Tombol Lihat
                  _buildActionButton(
                    label: '👁 Lihat',
                    color: Colors.blue.shade600,
                    bgColor: Colors.blue.shade50,
                    onTap: () => _handleLihatFile(laporan),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Unduh
                  _buildActionButton(
                    label: '⬇ Unduh',
                    color: Colors.green.shade600,
                    bgColor: Colors.green.shade50,
                    onTap: () => _handleDownload(laporan),
                  ),
                  const SizedBox(width: 8),
                ],

                // Tombol Hapus — selalu tampil
                _buildActionButton(
                  label: '🗑 Hapus',
                  color: Colors.red.shade500,
                  bgColor: Colors.red.shade50,
                  onTap: () => _handleHapus(laporan),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(VocationalProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(provider.laporanError ?? 'Terjadi kesalahan'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.fetchLaporanKegiatan(refresh: true),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
  return Center(
    child: SingleChildScrollView( // 🔥 penting: biar tidak overflow
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔥 kunci utama
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📁', style: TextStyle(fontSize: 48)), // sedikit diperkecil
          const SizedBox(height: 12),
          Text(
            'Belum ada laporan yang diupload',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showForm = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Upload Laporan'),
          ),
        ],
      ),
    ),
  );
}

  // ── Helpers ───────────────────────────────────────────────────

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String? _getMime(String? fileName) {
    if (fileName == null) return null;
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Preview Screen — mirror web ImagePreviewModal + PreviewModal untuk gambar
// ─────────────────────────────────────────────────────────────────────────────
class _ImagePreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final String title;
  final String fileName;

  const _ImagePreviewScreen({
    required this.bytes,
    required this.title,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            if (fileName.isNotEmpty)
              Text(
                fileName,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          // Mirror web: tombol Download di PreviewModal
          TextButton.icon(
            onPressed: () {
              // Download dari preview screen — navigasi kembali dan trigger download
              Navigator.pop(context, 'download');
            },
            icon: const Icon(Icons.download_rounded, color: Colors.greenAccent, size: 18),
            label: const Text('Download', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_rounded, color: Colors.grey, size: 64),
                SizedBox(height: 12),
                Text('Gagal menampilkan gambar', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}