import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../../academic/providers/academic_provider.dart';
import '../../../../data/models/reflection_model.dart';
import '../../../common/widgets/loading_widget.dart';
import '../../../common/widgets/error_widget.dart';

class HomeroomReflectionScreen extends StatefulWidget {
  const HomeroomReflectionScreen({super.key});

  @override
  State<HomeroomReflectionScreen> createState() => _HomeroomReflectionScreenState();
}

class _HomeroomReflectionScreenState extends State<HomeroomReflectionScreen> {
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
    context.read<StudentProvider>().fetchReflections(classId: _selectedClassId);
  }

  void _showAddReflectionSheet() {
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
      builder: (context) => AddReflectionForm(kelasId: _selectedClassId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Refleksi Kelas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Isi Refleksi Kelas', style: TextStyle(fontSize: 12)),
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
                if (provider.reflectionState == StudentLoadState.loading && provider.reflections.isEmpty) {
                  return const LoadingWidget();
                }

                if (provider.reflectionState == StudentLoadState.error && provider.reflections.isEmpty) {
                  return AppErrorWidget(
                    message: provider.reflectionError ?? 'Gagal memuat data',
                    onRetry: _fetchData,
                  );
                }

                final notes = provider.reflections;

                if (notes.isEmpty) {
                  return const Center(child: Text('Belum ada data refleksi'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                     _fetchData();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _ReflectionCard(note: note);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReflectionSheet,
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_circle_outline, size: 36, color: Colors.black),
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final ReflectionModel note;
  const _ReflectionCard({required this.note});

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Refleksi Kelas'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailItem('Tanggal Input', DateFormat('dd MMMM yyyy', 'id_ID').format(note.tanggal)),
              const Divider(),
              _detailItem('Perkembangan Siswa', note.capaian ?? '-'),
              const SizedBox(height: 12),
              _detailItem('Masalah / Tantangan', note.tantangan ?? '-'),
              if (note.rencana != null && note.rencana!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailItem('Rencana Tindak Lanjut', note.rencana!),
              ]
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
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
              note.capaian ?? 'Refleksi Harian',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                const Spacer(),
                _ActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'Detail',
                  onTap: () => _showDetailDialog(context),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    context.read<StudentProvider>().deleteReflection(note.id);
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

class AddReflectionForm extends StatefulWidget {
  final String kelasId;
  const AddReflectionForm({super.key, required this.kelasId});

  @override
  State<AddReflectionForm> createState() => _AddReflectionFormState();
}

class _AddReflectionFormState extends State<AddReflectionForm> {
  final _formKey = GlobalKey<FormState>();
  final _developmentController = TextEditingController();
  final _problemController = TextEditingController();
  final _planController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      // Mengirim field 'capaian' dan 'tantangan' sesuai ekspektasi server
      final Map<String, dynamic> data = {
        'kelas_id': widget.kelasId,
        'tanggal': DateFormat('yyyy-MM-dd').format(now),
        'capaian': _developmentController.text,
        'tantangan': _problemController.text,
        'rencana': _planController.text,
      };

      await context.read<StudentProvider>().addReflection(data);
      
      // Refresh list agar data terbaru dari server (yang tidak null) muncul
      if (mounted) {
        context.read<StudentProvider>().fetchReflections(classId: widget.kelasId);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil mengirim refleksi')),
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
                'Kirim Refleksi Kelas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              const Text('Perkembangan Siswa (Capaian)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _developmentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ketik perkembangan...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text('Masalah / Tantangan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _problemController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Isi masalah...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text('Rencana Tindak Lanjut (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _planController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Rencana ke depan...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      : const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
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
