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
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kelas terlebih dahulu')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddCleanlinessForm(kelasId: _selectedClassId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Kebersihan Kelas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Upload & kelola dokumen kebersihan', style: TextStyle(fontSize: 12)),
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

  void _showDetailDialog(BuildContext context) {
    String? imageUrl = note.fotoUrl;
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = '${ApiEndpoints.baseUrl}$imageUrl';
    }

    final bool isImage = imageUrl != null && (
        imageUrl.toLowerCase().endsWith('.jpg') ||
        imageUrl.toLowerCase().endsWith('.jpeg') ||
        imageUrl.toLowerCase().endsWith('.png') ||
        imageUrl.toLowerCase().endsWith('.gif')
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
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
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
    String? urlString = note.fotoUrl;
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lampiran foto/dokumen tidak tersedia')),
      );
      return;
    }

    // Handle relative paths from backend
    if (!urlString.startsWith('http')) {
      urlString = '${ApiEndpoints.baseUrl}$urlString';
    }

    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for some platforms where canLaunchUrl might return false for specific schemes
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
  final String kelasId;
  const AddCleanlinessForm({super.key, required this.kelasId});

  @override
  State<AddCleanlinessForm> createState() => _AddCleanlinessFormState();
}

class _AddCleanlinessFormState extends State<AddCleanlinessForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final _summaryController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    if (!_formKey.currentState!.validate() || 
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua field')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> data = {
        'kelas_id': widget.kelasId,
        'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'catatan': _summaryController.text,
      };

      if (_selectedFile != null && _selectedFile!.bytes != null) {
        data['file'] = base64Encode(_selectedFile!.bytes!);
        data['file_name'] = _selectedFile!.name;
      }

      await context.read<StudentProvider>().addCleanliness(data);
      
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
              const Text(
                'Upload Dokumen Baru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

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
                        _selectedDate == null ? 'Pilih tanggal' : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        style: TextStyle(color: _selectedDate == null ? Colors.grey : Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Catatan Kondisi', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _summaryController,
                decoration: InputDecoration(
                  hintText: 'catatan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text('Pilih File (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.upload_outlined, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile == null ? 'Klik untuk pilih file' : _selectedFile!.name,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Text(
                        'Maksimal 10MB',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Upload Dokumen', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
