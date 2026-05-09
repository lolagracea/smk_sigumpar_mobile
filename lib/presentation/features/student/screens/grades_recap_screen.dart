import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../../academic/providers/academic_provider.dart';
import '../../../common/widgets/loading_widget.dart';
import '../../../common/widgets/error_widget.dart';
import '../../../../data/models/student_model.dart';
import '../../../../data/models/grade_model.dart';

class GradesRecapScreen extends StatefulWidget {
  const GradesRecapScreen({super.key});

  @override
  State<GradesRecapScreen> createState() => _GradesRecapScreenState();
}

class _GradesRecapScreenState extends State<GradesRecapScreen> {
  String? _selectedSemester = '1';
  String? _selectedMapelId;
  final TextEditingController _searchController = TextEditingController();
  StudentModel? _selectedStudent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicProvider>().fetchStudents(refresh: true);
      context.read<AcademicProvider>().fetchSubjects(refresh: true);
    });
  }

  void _onStudentTap(StudentModel student) {
    setState(() {
      _selectedStudent = student;
    });
    context.read<StudentProvider>().fetchStudentGrades(
      studentId: student.id,
      semester: _selectedSemester,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedStudent != null) {
      return _GradeDetailView(
        student: _selectedStudent!,
        semester: _selectedSemester ?? '1',
        onBack: () => setState(() => _selectedStudent = null),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Rekap Nilai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('SMK Negeri 1 Sigumpar', style: TextStyle(fontSize: 12)),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E6091),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedSemester,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calendar_today),
                      hintText: 'Pilih Semester',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: '1', child: Text('Semester Ganjil')),
                      DropdownMenuItem(value: '2', child: Text('Semester Genap')),
                    ],
                    onChanged: (val) => setState(() => _selectedSemester = val),
                  ),
                  const SizedBox(height: 12),
                  Consumer<AcademicProvider>(
                    builder: (context, provider, child) {
                      return DropdownButtonFormField<String>(
                        value: _selectedMapelId,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.book_outlined),
                          hintText: 'Pilih Mapel',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: provider.subjects.map((s) {
                          return DropdownMenuItem(value: s.id, child: Text(s.namaMapel));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedMapelId = val),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Cari nama siswa...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {}, // Filtering handled by UI state
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cari', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Daftar Siswa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Consumer<AcademicProvider>(
              builder: (context, provider, child) {
                if (provider.studentState == AcademicLoadState.loading) {
                  return const LoadingWidget();
                }
                
                final students = provider.students.where((s) {
                  final matchesName = s.namaLengkap.toLowerCase().contains(_searchController.text.toLowerCase());
                  return matchesName;
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                        title: Text(student.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(student.kelasId), // Or class name if available
                        onTap: () => _onStudentTap(student),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeDetailView extends StatelessWidget {
  final StudentModel student;
  final String semester;
  final VoidCallback onBack;

  const _GradeDetailView({
    required this.student,
    required this.semester,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMK NEGERI 1 SIGUMPAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Nilai',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              student.namaLengkap,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            Text(
              'Semester ${semester == '1' ? 'Ganjil' : 'Genap'}',
              style: const TextStyle(color: Colors.grey),
            ),
            
            const SizedBox(height: 30),
            const Text(
              'Tabel Rekapan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Consumer<StudentProvider>(
              builder: (context, provider, child) {
                if (provider.studentGradeState == StudentLoadState.loading) {
                  return const LoadingWidget();
                }
                
                final grades = provider.studentGrades;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                    columns: const [
                      DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Mapel', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tugas', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('UTS', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('UAS', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Praktek', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: List.generate(grades.length, (index) {
                      final g = grades[index];
                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(g.subjectName)),
                        DataCell(Center(child: Text('${g.dailyScore}'))),
                        DataCell(Center(child: Text('${g.midScore}'))),
                        DataCell(Center(child: Text('${g.finalScore}'))),
                        DataCell(Center(child: Text('${g.practiceScore ?? 0}'))),
                      ]);
                    }),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
