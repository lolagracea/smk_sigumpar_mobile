import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smk_sigumpar/core/constants/route_names.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/student_model.dart';
import 'package:smk_sigumpar/data/models/pkl_grade_model.dart';
import 'package:smk_sigumpar/presentation/features/vocational/providers/vocational_provider.dart';

class PklGradeReportScreen extends StatefulWidget {
  const PklGradeReportScreen({super.key});

  @override
  State<PklGradeReportScreen> createState() => _PklGradeReportScreenState();
}

class _PklGradeReportScreenState extends State<PklGradeReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VocationalProvider>();
      provider.fetchPklClasses(refresh: true);
    });
  }

  void _loadGrades() {
    final provider = context.read<VocationalProvider>();
    provider.fetchPklGrades(
      refresh: true,
      classId: provider.selectedPklClass?.id,
      studentId: provider.selectedPklStudent?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai PKL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push(RouteNames.addPklGrade);
            },
          ),
        ],
      ),
      body: Consumer<VocationalProvider>(
        builder: (context, provider, child) {
          if (provider.state == VocationalLoadState.loading &&
              provider.pklGrades.isEmpty) {
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
                  _loadGrades();
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: provider.pklGrades.isEmpty
                    ? _EmptyState()
                    : _GradeList(grades: provider.pklGrades),
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

class _GradeList extends StatelessWidget {
  final List<PklGradeModel> grades;

  const _GradeList({required this.grades});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grades.length,
      itemBuilder: (context, index) {
        final grade = grades[index];
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
                  child: const Icon(Icons.grade, color: Color(0xFF2563EB)),
                ),
                title: Text(
                  grade.namaSiswa.isNotEmpty ? grade.namaSiswa : '(tanpa nama)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                subtitle: Text('Kelas: ${grade.namaKelas}'),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFBDBDBD)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Teknis: ${(grade.aspekTeknis ?? '').isEmpty ? '-' : grade.aspekTeknis}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                        'Non-Teknis: ${(grade.aspekNonTeknis ?? '').isEmpty ? '-' : grade.aspekNonTeknis}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                        'Kedisiplinan: ${(grade.aspekKedisiplinan ?? '').isEmpty ? '-' : grade.aspekKedisiplinan}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                        'Kerjasama: ${(grade.aspekKerjasama ?? '').isEmpty ? '-' : grade.aspekKerjasama}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                        'Inisiatif: ${(grade.aspekInisiatif ?? '').isEmpty ? '-' : grade.aspekInisiatif}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Nilai: ${grade.nilai ?? '-'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (grade.deskripsi != null &&
                        grade.deskripsi!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(grade.deskripsi!,
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
          Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada nilai PKL',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih kelas dan siswa, lalu tambahkan nilai',
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
