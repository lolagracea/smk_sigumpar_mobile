import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../../academic/providers/academic_provider.dart';
import '../../../common/widgets/loading_widget.dart';
import '../../../common/widgets/error_widget.dart';
import '../../../../data/models/grade_model.dart';

class GradesRecapScreen extends StatefulWidget {
  const GradesRecapScreen({super.key});

  @override
  State<GradesRecapScreen> createState() => _GradesRecapScreenState();
}

class _GradesRecapScreenState extends State<GradesRecapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedClassId;
  String? _selectedMapelId;
  String _selectedSemester = 'ganjil';
  String _selectedYear = '2024/2025';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicProvider>().fetchClasses(refresh: true).then((_) {
        final classes = context.read<AcademicProvider>().classes;
        if (classes.isNotEmpty) {
          setState(() => _selectedClassId = classes.first.id);
        }
      });
      context.read<AcademicProvider>().fetchSubjects(refresh: true);
    });
  }

  void _fetchGrades() {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kelas terlebih dahulu')),
      );
      return;
    }

    context.read<StudentProvider>().fetchGrades(
      classId: _selectedClassId!,
      semester: _selectedSemester,
      academicYear: _selectedYear,
      mapelId: _selectedMapelId,
    );
  }

  Color _getGradeColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Rekap Nilai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E6091),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Rekap Nilai'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRekapNilaiTab(),
          const Center(child: Text('Halaman Riwayat Nilai')),
        ],
      ),
    );
  }

  Widget _buildRekapNilaiTab() {
    return Column(
      children: [
        _buildFilterSection(),
        const Divider(height: 1),
        Expanded(child: _buildGradesList()),
        _buildLegend(),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Siswa (Wali Kelas)', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('Filter nilai berdasarkan kelas dan mata pelajaran.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          
          // Dropdown Kelas
          Consumer<AcademicProvider>(
            builder: (context, academic, child) {
              return DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: _inputDecoration('Pilih Kelas'),
                items: academic.classes.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.namaKelas));
                }).toList(),
                onChanged: (val) => setState(() => _selectedClassId = val),
              );
            },
          ),
          const SizedBox(height: 12),

          // Dropdown Mapel
          Consumer<AcademicProvider>(
            builder: (context, academic, child) {
              return DropdownButtonFormField<String>(
                value: _selectedMapelId,
                decoration: _inputDecoration('Semua Mapel'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Semua Mapel')),
                  ...academic.subjects.map((s) {
                    return DropdownMenuItem(value: s.id, child: Text(s.namaMapel));
                  }),
                ],
                onChanged: (val) => setState(() => _selectedMapelId = val),
              );
            },
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: _fetchGrades,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E6091),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.search, size: 20),
              label: const Text('Tampilkan Rekap', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildGradesList() {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        if (provider.gradeState == StudentLoadState.initial) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Pilih Kelas dan Tahun Ajar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text('lalu klik Tampilkan Rekap', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        if (provider.gradeState == StudentLoadState.loading) {
          return const LoadingWidget();
        }

        if (provider.gradeState == StudentLoadState.error) {
          return AppErrorWidget(message: provider.studentsError ?? 'Gagal memuat rekap nilai', onRetry: _fetchGrades);
        }

        final grades = provider.grades;
        if (grades.isEmpty) {
          return const Center(child: Text('Data nilai tidak ditemukan.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: grades.length,
          itemBuilder: (context, index) {
            final grade = grades[index];
            final color = _getGradeColor(grade.nilaiAkhir);

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(grade.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(grade.studentId, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      grade.nilaiAkhir.toStringAsFixed(0),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem(Colors.green, '> 85 (Sangat Baik)'),
          _legendItem(Colors.blue, '70-84 (Baik)'),
          _legendItem(Colors.orange, '60-69 (Cukup)'),
          _legendItem(Colors.red, '< 60 (Kurang)'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}
