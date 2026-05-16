import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/file_downloader.dart';
import '../providers/student_provider.dart';
import '../../academic/providers/academic_provider.dart';
import '../../../../data/models/cleanliness_model.dart';
import '../../../common/widgets/loading_widget.dart';
import '../../../common/widgets/error_widget.dart';

class CleanlinessRecapScreen extends StatefulWidget {
  const CleanlinessRecapScreen({super.key});

  @override
  State<CleanlinessRecapScreen> createState() => _CleanlinessRecapScreenState();
}

class _CleanlinessRecapScreenState extends State<CleanlinessRecapScreen> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    final academicProvider = context.read<AcademicProvider>();
    await academicProvider.fetchClasses(refresh: true);

    if (academicProvider.classes.isNotEmpty) {
      setState(() {
        _selectedClassId = academicProvider.classes.first.id;
      });
      _fetchData();
    }
  }

  void _fetchData() {
    context.read<StudentProvider>().fetchCleanliness(classId: _selectedClassId);
  }

  void _showAddCleanlinessSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AddCleanlinessForm(initialKelasId: _selectedClassId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('KEBERSIHAN KELAS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Penilaian kebersihan, catatan umum, dan dokumentasi kelas',
                style: TextStyle(fontSize: 10)),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E6091),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<AcademicProvider>(
              builder: (context, academic, child) {
                if (academic.classes.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'Pilih Kelas',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: academic.classes.map((c) {
                    return DropdownMenuItem(
                        value: c.id, child: Text(c.namaKelas));
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedClassId = val);
                    _fetchData();
                  },
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<StudentProvider>(
              builder: (context, provider, child) {
                if (provider.cleanlinessState == StudentLoadState.loading &&
                    provider.cleanlinessNotes.isEmpty) {
                  return const LoadingWidget();
                }

                if (provider.cleanlinessState == StudentLoadState.error &&
                    provider.cleanlinessNotes.isEmpty) {
                  return AppErrorWidget(
                    message: provider.cleanlinessError ?? 'Gagal memuat data',
                    onRetry: _fetchData,
                  );
                }

                final notes = provider.cleanlinessNotes;

                if (notes.isEmpty) {
                  return const Center(
                      child: Text('Belum ada data kebersihan'));
                }

                return RefreshIndicator(
                  onRefresh: () async => _fetchData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _CleanlinessCard(note: note);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCleanlinessSheet,
        backgroundColor: const Color(0xFF1E6091),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ─── CARD DENGAN PENILAIAN ASPEK ───────────────────────────
// ═══════════════════════════════════════════════════════════
class _CleanlinessCard extends StatelessWidget {
  final CleanlinessModel note;
  const _CleanlinessCard({required this.note});

  static const List<String> _aspectKeys = [
    'Meja & Kursi',
    'Lantai',
    'Papan Tulis',
    'Jendela & Pintu',
    'Sampah',
  ];

  /// Parse penilaian — handle Map maupun JSON String defensive
  Map<String, String> _parsePenilaian() {
    final result = <String, String>{};
    final raw = note.penilaian;

    if (raw.isNotEmpty) {
      raw.forEach((k, v) {
        if (v != null) result[k] = v.toString();
      });
    }

    return result;
  }

  Color _ratingColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'sangat bersih':
        return Colors.green.shade700;
      case 'bersih':
        return Colors.green;
      case 'cukup':
        return Colors.orange;
      case 'kotor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _ratingIcon(String rating) {
    switch (rating.toLowerCase()) {
      case 'sangat bersih':
      case 'bersih':
        return Icons.check_circle;
      case 'cukup':
        return Icons.info;
      case 'kotor':
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  String _formatUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    String cleanPath = url.startsWith('/') ? url : '/$url';
    String baseUrl = ApiEndpoints.baseUrl;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return '$baseUrl$cleanPath';
  }

  void _showDetailDialog(BuildContext context) {
    final String imageUrl = _formatUrl(note.fotoUrl);
    final bool isImage = imageUrl.isNotEmpty &&
        (imageUrl.toLowerCase().contains('.jpg') ||
            imageUrl.toLowerCase().contains('.jpeg') ||
            imageUrl.toLowerCase().contains('.png') ||
            imageUrl.toLowerCase().contains('.gif'));

    final penilaian = _parsePenilaian();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Kebersihan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isImage) ...[
                Container(
                  width: double.infinity,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                size: 40, color: Colors.grey),
                            Text('Gambar tidak ditemukan',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                            child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              ],
              _detailItem('Tanggal',
                  DateFormat('dd MMMM yyyy', 'id_ID').format(note.tanggal)),
              _detailItem('Catatan / Kondisi', note.catatan ?? '-'),
              if (penilaian.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Penilaian Item:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blueGrey)),
                const Divider(),
                ...penilaian.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 13)),
                      Text(e.value,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _ratingColor(e.value))),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.blueGrey)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    debugPrint('=== DEBUG DOWNLOAD CLEANLINESS ===');
    debugPrint('note.fotoUrl: ${note.fotoUrl}');
    debugPrint('note.id: ${note.id}');
    debugPrint('baseUrl: ${ApiEndpoints.baseUrl}');
    debugPrint('===================================');

    await FileDownloader.downloadFile(
      context: context,
      source: note.fotoUrl,
      fileName: 'kebersihan_${note.id}',
      baseUrl: ApiEndpoints.baseUrl,
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data?'),
        content: const Text(
            'Data kebersihan ini akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<StudentProvider>().deleteCleanliness(note.id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final penilaian = _parsePenilaian();
    final hasPenilaian = penilaian.isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: Tanggal & Delete ──────────────────────
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E6091).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 12, color: Color(0xFF1E6091)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy', 'id_ID')
                            .format(note.tanggal),
                        style: const TextStyle(
                          color: Color(0xFF1E6091),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── Catatan ───────────────────────────────────────
            if (note.catatan != null && note.catatan!.isNotEmpty) ...[
              Text(
                note.catatan!,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87),
              ),
              const SizedBox(height: 12),
            ],

            // ─── Penilaian Aspek (Meja, Lantai, Jendela, dll) ─
            if (hasPenilaian) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist_rounded,
                            size: 14, color: Colors.blueGrey.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Penilaian Aspek',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Aspek standar (urutan tetap)
                    ..._aspectKeys.where((k) => penilaian.containsKey(k)).map(
                          (aspect) {
                        final rating = penilaian[aspect] ?? '-';
                        return _AspectRow(
                          aspect: aspect,
                          rating: rating,
                          icon: _ratingIcon(rating),
                          color: _ratingColor(rating),
                        );
                      },
                    ),
                    // Aspek tambahan (kalau backend kirim aspek lain)
                    ...penilaian.entries
                        .where((e) => !_aspectKeys.contains(e.key))
                        .map((e) => _AspectRow(
                      aspect: e.key,
                      rating: e.value,
                      icon: _ratingIcon(e.value),
                      color: _ratingColor(e.value),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ─── Tombol Aksi ───────────────────────────────────
            Row(
              children: [
                _ActionButton(
                  icon: Icons.file_download_outlined,
                  label: 'Download',
                  onTap: () => _downloadFile(context),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'Detail',
                  onTap: () => _showDetailDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widget: row aspek dengan badge rating ─────────
class _AspectRow extends StatelessWidget {
  final String aspect;
  final String rating;
  final IconData icon;
  final Color color;

  const _AspectRow({
    required this.aspect,
    required this.rating,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              aspect,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              rating,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tombol aksi (Download / Detail) ──────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.blueGrey[700])),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ─── FORM TAMBAH KEBERSIHAN ────────────────────────────────
// ═══════════════════════════════════════════════════════════
class AddCleanlinessForm extends StatefulWidget {
  final String? initialKelasId;
  const AddCleanlinessForm({super.key, this.initialKelasId});

  @override
  State<AddCleanlinessForm> createState() => _AddCleanlinessFormState();
}

class _AddCleanlinessFormState extends State<AddCleanlinessForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate = DateTime.now();
  String? _selectedClassId;
  final _summaryController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  final List<String> _ratingOptions = [
    'Sangat Bersih',
    'Bersih',
    'Cukup',
    'Kotor',
  ];

  final Map<String, String> _aspectRatings = {
    'Meja & Kursi': 'Bersih',
    'Lantai': 'Bersih',
    'Papan Tulis': 'Bersih',
    'Jendela & Pintu': 'Bersih',
    'Sampah': 'Bersih',
  };

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialKelasId;
  }

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua field')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> data = {
        'kelas_id': _selectedClassId,
        'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'catatan': _summaryController.text,
        'penilaian': jsonEncode(_aspectRatings),
      };

      await context
          .read<StudentProvider>()
          .addCleanliness(data: data, file: _selectedFile);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil menambahkan data kebersihan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'KEBERSIHAN KELAS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Center(
                child: Text(
                  'Penilaian kebersihan, catatan umum, dan dokumentasi kelas',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Pilih Kelas ─────────────────────────────────
              const Text('Kelas (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Consumer<AcademicProvider>(
                builder: (context, academic, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'Pilih Kelas',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: academic.classes.map((c) {
                      return DropdownMenuItem(
                          value: c.id, child: Text(c.namaKelas));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedClassId = val),
                  );
                },
              ),
              const SizedBox(height: 16),

              // ─── Pilih Tanggal ───────────────────────────────
              const Text('Tanggal',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Pilih tanggal'
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.grey
                                : Colors.black),
                      ),
                      const Icon(Icons.calendar_today,
                          size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Penilaian Per Aspek ─────────────────────────
              const Text('Penilaian Per Aspek',
                  style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              ..._aspectRatings.keys.map((aspect) => _buildAspectRating(aspect)),

              const SizedBox(height: 24),

              // ─── Catatan Umum ────────────────────────────────
              const Text('Catatan Umum',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _summaryController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                  'Contoh: Kelas sudah cukup bersih, tetapi bagian sudut belakang masih perlu diperhatikan.',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // ─── Upload Foto ─────────────────────────────────
              const Text('Dokumentasi Foto (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.grey[300]!, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.camera_alt_outlined,
                          size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile == null
                            ? 'Klik untuk pilih foto'
                            : _selectedFile!.name,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ─── Tombol Simpan ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6091),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Simpan Data',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAspectRating(String aspect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(aspect, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _ratingOptions.map((option) {
              final isSelected = _aspectRatings[aspect] == option;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(
                    option,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _aspectRatings[aspect] = option;
                      });
                    }
                  },
                  selectedColor: const Color(0xFF1E6091),
                  backgroundColor: Colors.grey[200],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}