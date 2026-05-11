import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/student_model.dart';
import 'package:smk_sigumpar/presentation/features/vocational/providers/vocational_provider.dart';

class AddPklLocationScreen extends StatefulWidget {
  const AddPklLocationScreen({super.key});

  @override
  State<AddPklLocationScreen> createState() => _AddPklLocationScreenState();
}

class _AddPklLocationScreenState extends State<AddPklLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  ClassModel? _selectedClass;
  StudentModel? _selectedStudent;
  final _namaPerusahaanController = TextEditingController();
  final _alamatPerusahaanController = TextEditingController();
  final _posisiSiswaController = TextEditingController();
  final _pembimbingIndustriController = TextEditingController();
  final _kontakPembimbingController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _tanggalMulaiController = TextEditingController();
  final _tanggalSelesaiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocationalProvider>().fetchPklClasses(refresh: true);
    });
  }

  @override
  void dispose() {
    _namaPerusahaanController.dispose();
    _alamatPerusahaanController.dispose();
    _posisiSiswaController.dispose();
    _pembimbingIndustriController.dispose();
    _kontakPembimbingController.dispose();
    _deskripsiController.dispose();
    _tanggalMulaiController.dispose();
    _tanggalSelesaiController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kelas terlebih dahulu')),
      );
      return;
    }
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih siswa terlebih dahulu')),
      );
      return;
    }

    final provider = context.read<VocationalProvider>();
    provider.submitPklLocationReport({
      'siswa_id': _selectedStudent!.id,
      'nama_siswa': _selectedStudent!.namaLengkap,
      'kelas_id': _selectedClass!.id,
      'nama_kelas': _selectedClass!.namaKelas,
      'nama_perusahaan': _namaPerusahaanController.text.trim(),
      'alamat_perusahaan': _alamatPerusahaanController.text.trim(),
      'posisi_siswa': _posisiSiswaController.text.trim(),
      'pembimbing_industri': _pembimbingIndustriController.text.trim(),
      'kontak_pembimbing': _kontakPembimbingController.text.trim(),
      'tanggal_mulai': _tanggalMulaiController.text.trim(),
      'tanggal_selesai': _tanggalSelesaiController.text.trim(),
      'deskripsi': _deskripsiController.text.trim(),
    }).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan lokasi PKL berhasil disimpan')),
        );
        context.pop();
      }
    }).catchError((e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Lokasi PKL'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<VocationalProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(title: 'Data Siswa'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ClassModel>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Kelas *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: provider.pklClasses.map((kelas) {
                      return DropdownMenuItem(
                        value: kelas,
                        child: Text(kelas.namaKelas),
                      );
                    }).toList(),
                    onChanged: (kelas) {
                      setState(() {
                        _selectedClass = kelas;
                        _selectedStudent = null;
                      });
                      if (kelas != null) {
                        provider.fetchPklStudents(
                            classId: kelas.id, refresh: true);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<StudentModel>(
                    value: _selectedStudent,
                    decoration: const InputDecoration(
                      labelText: 'Siswa *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: provider.pklStudents.map((siswa) {
                      return DropdownMenuItem(
                        value: siswa,
                        child: Text('${siswa.namaLengkap} (${siswa.nisn})'),
                      );
                    }).toList(),
                    onChanged: (siswa) {
                      setState(() => _selectedStudent = siswa);
                    },
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Data Lokasi PKL'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _namaPerusahaanController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Perusahaan *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _alamatPerusahaanController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Perusahaan *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _posisiSiswaController,
                    decoration: const InputDecoration(
                      labelText: 'Posisi Siswa',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tanggalMulaiController,
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Mulai *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(_tanggalMulaiController),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Wajib diisi'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _tanggalSelesaiController,
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Selesai',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.event),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(_tanggalSelesaiController),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pembimbingIndustriController,
                    decoration: const InputDecoration(
                      labelText: 'Pembimbing Industri',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _kontakPembimbingController,
                    decoration: const InputDecoration(
                      labelText: 'Kontak Pembimbing',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deskripsiController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: provider.state == VocationalLoadState.loading
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: provider.state == VocationalLoadState.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
