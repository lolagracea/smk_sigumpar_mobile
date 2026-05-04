import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/student_provider.dart';
import '../../../../data/models/cleanliness_model.dart';
import '../../../common/widgets/loading_widget.dart';
import '../../../common/widgets/error_widget.dart';

class CleanlinessRecapScreen extends StatefulWidget {
  const CleanlinessRecapScreen({super.key});

  @override
  State<CleanlinessRecapScreen> createState() => _CleanlinessRecapScreenState();
}

class _CleanlinessRecapScreenState extends State<CleanlinessRecapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchCleanliness(refresh: true);
    });
  }

  void _showAddCleanlinessSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddCleanlinessForm(),
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
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.cleanlinessState == StudentLoadState.loading && provider.cleanlinessNotes.isEmpty) {
            return const LoadingWidget();
          }

          if (provider.cleanlinessState == StudentLoadState.error && provider.cleanlinessNotes.isEmpty) {
            return AppErrorWidget(
              message: provider.cleanlinessError ?? 'Gagal memuat data',
              onRetry: () => provider.fetchCleanliness(refresh: true),
            );
          }

          final notes = provider.cleanlinessNotes;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Kebersihan Kelas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchCleanliness(refresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _CleanlinessCard(note: note);
                    },
                  ),
                ),
              ),
            ],
          );
        },
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
              note.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy-MM-dd').format(note.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(icon: Icons.file_download_outlined, onTap: () {}),
                const SizedBox(width: 8),
                _ActionButton(icon: Icons.delete_outline, onTap: () {}),
                const SizedBox(width: 8),
                _ActionButton(icon: Icons.visibility_outlined, onTap: () {}),
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
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Colors.grey[600]),
      ),
    );
  }
}

class AddCleanlinessForm extends StatefulWidget {
  const AddCleanlinessForm({super.key});

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
      allowedExtensions: ['pdf', 'docx'],
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || 
        _selectedDate == null || 
        _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua field dan pilih file')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final String formattedDate = DateFormat('d MMMM', 'id_ID').format(_selectedDate!);
      final Map<String, dynamic> data = {
        'title': 'Kebersihan Kelas $formattedDate',
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'summary': _summaryController.text,
      };

      if (_selectedFile != null && _selectedFile!.bytes != null) {
        data['file'] = base64Encode(_selectedFile!.bytes!);
        data['file_name'] = _selectedFile!.name;
      }

      await context.read<StudentProvider>().addCleanlinessNote(data);
      
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
              const Text('Pilih File (PDF/DOCX)', style: TextStyle(fontWeight: FontWeight.bold)),
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
