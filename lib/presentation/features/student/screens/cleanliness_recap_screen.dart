import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';
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
            Text('KEBERSIHAN KELAS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Penilaian kebersihan, catatan umum, dan dokumentasi kelas', style: TextStyle(fontSize: 10)),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: academic.classes.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.namaKelas));
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
                if (provider.cleanlinessState == StudentLoadState.loading && provider.cleanlinessNotes.isEmpty) {
                  return const LoadingWidget();
                }

                if (provider.cleanlinessState == StudentLoadState.error && provider.cleanlinessNotes.isEmpty) {
                  return AppErrorWidget(
                    message: provider.cleanlinessError ?? 'Gagal memuat data',
                    onRetry: _fetchData,
                  );
                }

                final notes = provider.cleanlinessNotes;

                if (notes.isEmpty) {
                  return const Center(child: Text('Belum ada data kebersihan'));
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
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_circle_outline, size: 36, color: Colors.black),
      ),
    );
  }
}

class _CleanlinessCard extends StatelessWidget {
  final CleanlinessModel note;
  const _CleanlinessCard({required this.note});

  String _formatUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    
    // Ensure the path starts with a slash
    String cleanPath = url.startsWith('/') ? url : '/$url';
    
    // ApiEndpoints.baseUrl is usually http://localhost:8001
    String baseUrl = ApiEndpoints.baseUrl;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    return '$baseUrl$cleanPath';
  }

  void _showDetailDialog(BuildContext context) {
    final String imageUrl = _formatUrl(note.fotoUrl);

    final bool isImage = imageUrl.isNotEmpty && (
        imageUrl.toLowerCase().contains('.jpg') ||
        imageUrl.toLowerCase().contains('.jpeg') ||
        imageUrl.toLowerCase().contains('.png') ||
        imageUrl.toLowerCase().contains('.gif')
    );

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
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            Text('Gambar tidak ditemukan', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              ],
              _detailItem('Tanggal', DateFormat('dd MMMM yyyy', 'id_ID').format(note.tanggal)),
              _detailItem('Catatan / Kondisi', note.catatan ?? '-'),
              if (note.penilaian.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Penilaian Item:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                const Divider(),
                ...note.penilaian.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 13)),
                      Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    final String urlString = _formatUrl(note.fotoUrl);
    
    if (urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lampiran foto/dokumen tidak tersedia')),
      );
      return;
    }

    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka lampiran: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.catatan ?? 'Kebersihan Kelas',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy-MM-dd').format(note.tanggal),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(
                  icon: Icons.file_download_outlined,
                  label: 'Lampiran',
                  onTap: () => _downloadFile(context),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'Detail',
                  onTap: () => _showDetailDialog(context),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    context.read<StudentProvider>().deleteCleanliness(note.id);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            Text(label, style: TextStyle(fontSize: 12, color: Colors.blueGrey[700])),
          ],
        ),
      ),
    );
  }
}

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

  final List<String> _ratingOptions = ['Sangat Bersih', 'Bersih', 'Cukup', 'Kotor'];
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

      await context.read<StudentProvider>().addCleanliness(data: data, file: _selectedFile);
      
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

              const Text('Kelas (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Consumer<AcademicProvider>(
                builder: (context, academic, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'Pilih Kelas',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: academic.classes.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.namaKelas));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedClassId = val),
                  );
                },
              ),
              const SizedBox(height: 16),

              const Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null ? 'Pilih tanggal' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        style: TextStyle(color: _selectedDate == null ? Colors.grey : Colors.black),
                      ),
                      const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Penilaian Per Aspek', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              ..._aspectRatings.keys.map((aspect) => _buildAspectRating(aspect)),
              
              const SizedBox(height: 24),
              const Text('Catatan Umum', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _summaryController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: Kelas sudah cukup bersih, tetapi bagian sudut belakang masih perlu diperhatikan.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text('Dokumentasi Foto (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile == null ? 'Klik untuk pilih foto' : _selectedFile!.name,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6091),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Data', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  label: Text(option, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
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
