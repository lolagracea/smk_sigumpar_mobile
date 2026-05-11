import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smk_sigumpar/core/constants/route_names.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/student_model.dart';
import 'package:smk_sigumpar/data/models/pkl_location_model.dart';
import 'package:smk_sigumpar/presentation/features/vocational/providers/vocational_provider.dart';

class PklLocationReportScreen extends StatefulWidget {
  const PklLocationReportScreen({super.key});

  @override
  State<PklLocationReportScreen> createState() =>
      _PklLocationReportScreenState();
}

class _PklLocationReportScreenState extends State<PklLocationReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VocationalProvider>();
      provider.fetchPklClasses(refresh: true);
      provider.fetchPklLocationReports(refresh: true);
    });
  }

  void _loadReports() {
    final provider = context.read<VocationalProvider>();
    provider.fetchPklLocationReports(
      refresh: true,
      classId: provider.selectedPklClass?.id,
      studentId: provider.selectedPklStudent?.id,
    );
  }

  void _loadAllReports() {
    final provider = context.read<VocationalProvider>();
    provider.clearSelection();
    provider.fetchPklLocationReports(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Lokasi PKL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push(RouteNames.addPklLocation);
              if (mounted) _loadReports();
            },
          ),
        ],
      ),
      body: Consumer<VocationalProvider>(
        builder: (context, provider, child) {
          if (provider.state == VocationalLoadState.loading &&
              provider.pklLocationReports.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _ClassStudentSelector(
                onClassSelected: (kelas) {
                  provider.selectPklClass(kelas);
                  provider.fetchPklStudents(classId: kelas.id, refresh: true);
                },
                onStudentSelected: (siswa) {
                  provider.selectPklStudent(siswa);
                  _loadReports();
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: provider.pklLocationReports.isEmpty
                    ? _EmptyState()
                    : _ReportList(reports: provider.pklLocationReports),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassStudentSelector extends StatelessWidget {
  final Function(ClassModel) onClassSelected;
  final Function(StudentModel) onStudentSelected;

  const _ClassStudentSelector({
    required this.onClassSelected,
    required this.onStudentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VocationalProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih Kelas & Siswa',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ClassModel>(
                value: provider.selectedPklClass,
                decoration: const InputDecoration(
                  labelText: 'Kelas',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_),
                ),
                items: provider.pklClasses.map((kelas) {
                  return DropdownMenuItem(
                      value: kelas, child: Text(kelas.namaKelas));
                }).toList(),
                onChanged: (kelas) {
                  if (kelas != null) onClassSelected(kelas);
                },
              ),
              const SizedBox(height: 12),
              if (provider.selectedPklClass != null)
                DropdownButtonFormField<StudentModel>(
                  value: provider.selectedPklStudent,
                  decoration: const InputDecoration(
                    labelText: 'Siswa',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: provider.pklStudents.map((siswa) {
                    return DropdownMenuItem(
                        value: siswa,
                        child: Text('${siswa.namaLengkap} (${siswa.nisn})'));
                  }).toList(),
                  onChanged: (siswa) {
                    if (siswa != null) onStudentSelected(siswa);
                  },
                ),
              if (provider.selectedPklClass != null &&
                  provider.pklStudents.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Memuat data siswa...',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportList extends StatelessWidget {
  final List<PklLocationModel> reports;

  const _ReportList({required this.reports});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: const Icon(Icons.business, color: Color(0xFF2563EB)),
                ),
                title: Text(
                  report.namaPerusahaan.isNotEmpty
                      ? report.namaPerusahaan
                      : '(tanpa perusahaan)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                subtitle: Text(
                    'Siswa: ${report.namaSiswa} • Kelas: ${report.namaKelas}'),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFBDBDBD)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (report.posisiSiswa != null)
                      Text('Posisi: ${report.posisiSiswa}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    if (report.pembimbingIndustri != null)
                      Text('Pembimbing: ${report.pembimbingIndustri}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    Text('Alamat: ${report.alamatPerusahaan}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    if (report.tanggalMulai != null)
                      Text(
                        'Periode: ${report.tanggalMulai}${report.tanggalSelesai != null ? ' s/d ${report.tanggalSelesai}' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (report.deskripsi != null &&
                        report.deskripsi!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(report.deskripsi!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada laporan lokasi PKL',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih kelas dan siswa, lalu tambahkan laporan',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
