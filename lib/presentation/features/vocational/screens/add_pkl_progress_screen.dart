import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/student_model.dart';
import 'package:smk_sigumpar/data/models/pkl_location_model.dart';
import 'package:smk_sigumpar/presentation/features/vocational/providers/vocational_provider.dart';

class AddPklProgressScreen extends StatefulWidget {
  const AddPklProgressScreen({super.key});

  @override
  State<AddPklProgressScreen> createState() => _AddPklProgressScreenState();
}

class _AddPklProgressScreenState extends State<AddPklProgressScreen> {
  final _formKey = GlobalKey<FormState>();
  ClassModel? _selectedClass;
  StudentModel? _selectedStudent;
  PklLocationModel? _selectedLokasi;
  final _judulKegiatanController = TextEditingController();
  final _deskripsiKegiatanController = TextEditingController();
  final _tanggalKegiatanController = TextEditingController();
  final _jamMulaiController = TextEditingController();
  final _jamSelesaiController = TextEditingController();
  final _mingguKeController = TextEditingController();
  final _capaianController = TextEditingController();
  final _kendalaController = TextEditingController();

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
    _judulKegiatanController.dispose();
    _deskripsiKegiatanController.dispose();
    _tanggalKegiatanController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    _mingguKeController.dispose();
    _capaianController.dispose();
    _kendalaController.dispose();
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

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
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
    final data = {
      'siswa_id': _selectedStudent!.id,
      'nama_siswa': _selectedStudent!.namaLengkap,
      'kelas_id': _selectedClass!.id,
      'nama_kelas': _selectedClass!.namaKelas,
      'judul_kegiatan': _judulKegiatanController.text.trim(),
      'deskripsi_kegiatan': _deskripsiKegiatanController.text.trim(),
      'tanggal_kegiatan': _tanggalKegiatanController.text.trim(),
      'minggu_ke': int.tryParse(_mingguKeController.text.trim()) ?? 1,
      'jam_mulai': _jamMulaiController.text.trim(),
      'jam_selesai': _jamSelesaiController.text.trim(),
      'capaian': _capaianController.text.trim(),
      'kendala': _kendalaController.text.trim(),
    };
    if (_selectedLokasi != null) {
      data['pkl_lokasi_id'] = _selectedLokasi!.id;
    }

    provider.submitPklProgressReport(data).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Laporan kemajuan PKL berhasil disimpan')),
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
        title: const Text('Tambah Kemajuan PKL'),
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
                  _SectionTitle(title: 'Data Kemajuan PKL'),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _judulKegiatanController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Kegiatan *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tanggalKegiatanController,
                          decoration: const InputDecoration(
                            labelText: 'Tanggal *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(_tanggalKegiatanController),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Wajib diisi'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _mingguKeController,
                          decoration: const InputDecoration(
                            labelText: 'Minggu Ke-*',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_view_week),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Wajib diisi'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _jamMulaiController,
                          decoration: const InputDecoration(
                            labelText: 'Jam Mulai',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          readOnly: true,
                          onTap: () => _selectTime(_jamMulaiController),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _jamSelesaiController,
                    decoration: const InputDecoration(
                      labelText: 'Jam Selesai',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time_filled),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(_jamSelesaiController),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deskripsiKegiatanController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Kegiatan *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 4,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _capaianController,
                    decoration: const InputDecoration(
                      labelText: 'Capaian',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.emoji_events),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _kendalaController,
                    decoration: const InputDecoration(
                      labelText: 'Kendala',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning_amber),
                    ),
                    maxLines: 2,
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
