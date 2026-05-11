import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/student_model.dart';
import 'package:smk_sigumpar/data/models/pkl_location_model.dart';
import 'package:smk_sigumpar/presentation/features/vocational/providers/vocational_provider.dart';

class AddPklGradeScreen extends StatefulWidget {
  const AddPklGradeScreen({super.key});

  @override
  State<AddPklGradeScreen> createState() => _AddPklGradeScreenState();
}

class _AddPklGradeScreenState extends State<AddPklGradeScreen> {
  final _formKey = GlobalKey<FormState>();
  ClassModel? _selectedClass;
  StudentModel? _selectedStudent;
  PklLocationModel? _selectedLokasi;
  final _aspekTeknisController = TextEditingController();
  final _aspekNonTeknisController = TextEditingController();
  final _aspekKedisiplinanController = TextEditingController();
  final _aspekKerjasamaController = TextEditingController();
  final _aspekInisiatifController = TextEditingController();
  final _nilaiController = TextEditingController();
  final _deskripsiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VocationalProvider>();
      provider.fetchPklClasses(refresh: true);
      provider.fetchPklLocationReports(refresh: true);
    });
  }

  @override
  void dispose() {
    _aspekTeknisController.dispose();
    _aspekNonTeknisController.dispose();
    _aspekKedisiplinanController.dispose();
    _aspekKerjasamaController.dispose();
    _aspekInisiatifController.dispose();
    _nilaiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
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
    final data = {
      'siswa_id': _selectedStudent!.id,
      'nama_siswa': _selectedStudent!.namaLengkap,
      'kelas_id': _selectedClass!.id,
      'nama_kelas': _selectedClass!.namaKelas,
      'aspek_teknis': _aspekTeknisController.text.trim(),
      'aspek_non_teknis': _aspekNonTeknisController.text.trim(),
      'aspek_kedisiplinan': _aspekKedisiplinanController.text.trim(),
      'aspek_kerjasama': _aspekKerjasamaController.text.trim(),
      'aspek_inisiatif': _aspekInisiatifController.text.trim(),
      'nilai': _nilaiController.text.trim(),
      'deskripsi': _deskripsiController.text.trim(),
    };
    if (_selectedLokasi != null) {
      data['pkl_lokasi_id'] = _selectedLokasi!.id;
    }

    provider.submitPklGrade(data).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nilai PKL berhasil disimpan')),
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
        title: const Text('Tambah Nilai PKL'),
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PklLocationModel>(
                    value: _selectedLokasi,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi PKL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    items: provider.pklLocationReports
                        .where((lokasi) =>
                            lokasi.siswaId == (_selectedStudent?.id ?? ''))
                        .map((lokasi) {
                      return DropdownMenuItem(
                        value: lokasi,
                        child: Text(
                            '${lokasi.namaPerusahaan} - ${lokasi.namaSiswa}'),
                      );
                    }).toList(),
                    onChanged: (lokasi) {
                      setState(() => _selectedLokasi = lokasi);
                    },
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Penilaian'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _aspekTeknisController,
                    decoration: const InputDecoration(
                      labelText: 'Aspek Teknis',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.build),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _aspekNonTeknisController,
                    decoration: const InputDecoration(
                      labelText: 'Aspek Non-Teknis',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.psychology),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _aspekKedisiplinanController,
                    decoration: const InputDecoration(
                      labelText: 'Kedisiplinan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.rule),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _aspekKerjasamaController,
                    decoration: const InputDecoration(
                      labelText: 'Kerjasama',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.handshake),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _aspekInisiatifController,
                    decoration: const InputDecoration(
                      labelText: 'Inisiatif',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lightbulb),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nilaiController,
                    decoration: const InputDecoration(
                      labelText: 'Nilai Akhir *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grade),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
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
