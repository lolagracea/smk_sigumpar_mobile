import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../providers/student_provider.dart';
import '../../academic/providers/academic_provider.dart';
import '../../../../data/models/parenting_note_model.dart';
import '../../../common/widgets/loading_widget.dart';
import '../../../common/widgets/error_widget.dart';

class ParentingNotesScreen extends StatefulWidget {
  const ParentingNotesScreen({super.key});

  @override
  State<ParentingNotesScreen> createState() => _ParentingNotesScreenState();
}

class _ParentingNotesScreenState extends State<ParentingNotesScreen> {
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
      _fetchNotes();
    }
  }

  void _fetchNotes() {
    context.read<StudentProvider>().fetchParentingNotes(classId: _selectedClassId);
  }

  void _showAddParentingSheet() {
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
      builder: (context) => AddParentingForm(kelasId: _selectedClassId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Parenting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Upload & kelola dokumen parenting', style: TextStyle(fontSize: 12)),
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
                    _fetchNotes();
                  },
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<StudentProvider>(
              builder: (context, provider, child) {
                if (provider.parentingState == StudentLoadState.loading && provider.parentingNotes.isEmpty) {
                  return const LoadingWidget();
                }

                if (provider.parentingState == StudentLoadState.error && provider.parentingNotes.isEmpty) {
                  return AppErrorWidget(
                    message: provider.parentingError ?? 'Gagal memuat data',
                    onRetry: _fetchNotes,
                  );
                }

                final notes = provider.parentingNotes;

                if (notes.isEmpty) {
                  return const Center(child: Text('Belum ada data parenting'));
                }

                return RefreshIndicator(
                  onRefresh: () async => _fetchNotes(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _ParentingCard(note: note);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddParentingSheet,
        backgroundColor: Colors.white,
        child: const Icon(Icons.add_circle_outline, size: 36, color: Colors.black),
      ),
    );
  }
}

class _ParentingCard extends StatelessWidget {
  final ParentingNoteModel note;
  const _ParentingCard({required this.note});

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note.agenda ?? 'Detail Parenting'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _AttachmentPreview(
                urlString: note.dokumentasi ?? note.fotoUrl,
                onOpen: () => _downloadFile(context),
              ),
              const SizedBox(height: 16),
              _detailItem('Tanggal', DateFormat('dd MMMM yyyy', 'id_ID').format(note.tanggal)),
              _detailItem('Agenda', note.agenda ?? '-'),
              _detailItem('Ringkasan', note.ringkasan ?? '-'),
              _detailItem('Kehadiran Ortu', '${note.kehadiranOrtu} orang'),
              if (note.catatan != null && note.catatan!.isNotEmpty) 
                _detailItem('Catatan Tambahan', note.catatan!),
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    String? urlString = note.dokumentasi ?? note.fotoUrl;
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lampiran tidak tersedia')));
      return;
    }

    Uri uri;
    if (urlString.startsWith('http')) {
      uri = Uri.parse(urlString);
    } else if (urlString.startsWith('JVBERi')) {
      uri = Uri.parse('data:application/pdf;base64,$urlString');
    } else if (urlString.startsWith('/9j/') || urlString.startsWith('iVBORw0KGgo')) {
      String mime = urlString.startsWith('/9j/') ? 'image/jpeg' : 'image/png';
      uri = Uri.parse('data:$mime;base64,$urlString');
    } else if (urlString.startsWith('data:')) {
      uri = Uri.parse(urlString);
    } else {
      String path = urlString.startsWith('/') ? urlString : '/$urlString';
      uri = Uri.parse('${ApiEndpoints.baseUrl}$path');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka file: $e')));
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    (note.agenda ?? 'Parenting').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DOKUMEN',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(note.tanggal),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(
                  icon: Icons.file_download_outlined,
                  onTap: () => _downloadFile(context),
                  label: 'Download',
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.visibility_outlined,
                  onTap: () => _showDetailDialog(context),
                  label: 'Detail',
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    context.read<StudentProvider>().deleteParentingNote(note.id);
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

class _AttachmentPreview extends StatefulWidget {
  final String? urlString;
  final VoidCallback onOpen;

  const _AttachmentPreview({required this.urlString, required this.onOpen});

  @override
  State<_AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<_AttachmentPreview> {
  bool isPdf = false;
  bool isBase64Image = false;
  bool isNetworkImage = false;
  String finalUrl = '';
  Uint8List? decodedBytes;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _processAttachment();
  }

  Future<void> _processAttachment() async {
    final url = widget.urlString;
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    isPdf = url.startsWith('JVBERi') || url.toLowerCase().endsWith('.pdf');
    isBase64Image = url.startsWith('/9j/') || 
                    url.startsWith('iVBORw0KGgo') || 
                    url.startsWith('data:image');
    
    if (!isPdf && !isBase64Image) {
       finalUrl = url.startsWith('http') 
           ? url 
           : '${ApiEndpoints.baseUrl}${url.startsWith('/') ? url : '/$url'}';
       
       isNetworkImage = finalUrl.toLowerCase().endsWith('.jpg') || 
                        finalUrl.toLowerCase().endsWith('.jpeg') || 
                        finalUrl.toLowerCase().endsWith('.png') ||
                        finalUrl.toLowerCase().endsWith('.gif') ||
                        finalUrl.contains('/storage/');
    }

    if (isBase64Image) {
      try {
        final String base64Str = url.contains(',') ? url.split(',').last : url;
        // Offload decoding to isolate to prevent UI lag
        decodedBytes = await compute(base64Decode, base64Str);
      } catch (e) {
        debugPrint('Error decoding base64: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urlString == null || widget.urlString!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isProcessing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lampiran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        if (isBase64Image && decodedBytes != null)
          _ImageFrame(child: Image.memory(
            decodedBytes!,
            fit: BoxFit.cover,
            cacheHeight: 400,
          ))
        else if (isNetworkImage)
          _ImageFrame(child: Image.network(
            finalUrl,
            fit: BoxFit.cover,
            cacheHeight: 400,
            loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          ))
        else if (isPdf)
          const Center(child: Column(children: [Icon(Icons.picture_as_pdf, size: 60, color: Colors.red), Text('File PDF', style: TextStyle(fontSize: 12))]))
        else
          const Center(child: Icon(Icons.insert_drive_file, size: 60, color: Colors.grey)),
        
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onOpen,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text((isBase64Image || isNetworkImage) ? 'Lihat Full Screen' : 'Buka Dokumen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6091),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const Divider(height: 32),
      ],
    );
  }
}

class _ImageFrame extends StatelessWidget {
  final Widget child;
  const _ImageFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  const _ActionButton({required this.icon, required this.onTap, required this.label});

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

class AddParentingForm extends StatefulWidget {
  final String kelasId;
  const AddParentingForm({super.key, required this.kelasId});

  @override
  State<AddParentingForm> createState() => _AddParentingFormState();
}

class _AddParentingFormState extends State<AddParentingForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final _agendaController = TextEditingController();
  final _ringkasanController = TextEditingController();
  final _kehadiranController = TextEditingController();
  final _catatanController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'jpg', 'png'],
      withData: true,
    );
    if (result != null) setState(() => _selectedFile = result.files.first);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi data wajib')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> data = {
        'kelas_id': widget.kelasId,
        'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'agenda': _agendaController.text,
        'ringkasan': _ringkasanController.text,
        'kehadiran_ortu': int.tryParse(_kehadiranController.text) ?? 0,
        'catatan': _catatanController.text,
      };

      if (_selectedFile != null && _selectedFile!.bytes != null) {
        data['dokumentasi'] = base64Encode(_selectedFile!.bytes!);
        data['file_name'] = _selectedFile!.name;
      }

      await context.read<StudentProvider>().addParentingNote(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tambahkan Parenting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedDate == null ? 'Pilih Tanggal' : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _agendaController, decoration: const InputDecoration(labelText: 'Agenda/Kegiatan', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _ringkasanController, decoration: const InputDecoration(labelText: 'Ringkasan', border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 16),
              TextFormField(controller: _kehadiranController, decoration: const InputDecoration(labelText: 'Jumlah Kehadiran Ortu', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              TextFormField(controller: _catatanController, decoration: const InputDecoration(labelText: 'Catatan Tambahan (Opsional)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              const Text('Dokumentasi (PDF/Image)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_selectedFile == null ? 'Pilih File' : _selectedFile!.name),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E6091), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN DATA'),
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
