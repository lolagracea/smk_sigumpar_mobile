import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smk_sigumpar/presentation/common/providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../../academic/providers/academic_provider.dart';
import '../../../common/widgets/loading_widget.dart';
import '../../../common/widgets/error_widget.dart';

class AttendanceRecapScreen extends StatefulWidget {
  const AttendanceRecapScreen({super.key});

  @override
  State<AttendanceRecapScreen> createState() => _AttendanceRecapScreenState();
}

class _AttendanceRecapScreenState extends State<AttendanceRecapScreen> {
  String? _selectedClassId;
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    final authProvider = context.read<AuthProvider>();
    final academicProvider = context.read<AcademicProvider>();
    
    // Fetch classes for the teacher/wali
    await academicProvider.fetchClasses(refresh: true);
    
    if (academicProvider.classes.isNotEmpty) {
      setState(() {
        _selectedClassId = academicProvider.classes.first.id;
      });
      _fetchSummary();
    }
  }

  void _fetchSummary() {
    if (_selectedClassId == null) return;
    
    context.read<StudentProvider>().fetchAttendanceSummary(
      classId: _selectedClassId!,
      month: _selectedDate != null ? DateFormat('MM').format(_selectedDate!) : null,
      year: _selectedDate != null ? DateFormat('yyyy').format(_selectedDate!) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMK NEGERI 1 SIGUMPAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Absensi Siswa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now()),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Filter Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<AcademicProvider>(
                          builder: (context, provider, child) {
                            return DropdownButtonFormField<String>(
                              value: _selectedClassId,
                              decoration: InputDecoration(
                                fillColor: Colors.grey[200],
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              items: provider.classes.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.namaKelas),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedClassId = val),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate == null ? 'mm/dd/yyyy' : DateFormat('MM/dd/yyyy').format(_selectedDate!),
                                  style: TextStyle(color: _selectedDate == null ? Colors.grey : Colors.black),
                                ),
                                const Icon(Icons.calendar_today_outlined, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama siswa',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _fetchSummary,
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
            
            const SizedBox(height: 30),
            const Text(
              'Tabel Rekapan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Table
            Consumer<StudentProvider>(
              builder: (context, provider, child) {
                if (provider.summaryState == StudentLoadState.loading) {
                  return const LoadingWidget();
                }
                if (provider.summaryState == StudentLoadState.error) {
                  return AppErrorWidget(
                    message: provider.summaryError ?? 'Gagal memuat data',
                    onRetry: _fetchSummary,
                  );
                }
                
                final summaries = provider.summaries.where((s) {
                  if (_searchController.text.isEmpty) return true;
                  return s.studentName.toLowerCase().contains(_searchController.text.toLowerCase());
                }).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                    columns: const [
                      DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nama Siswa', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Hadir', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Izin', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Sakit', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Alpha', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: List.generate(summaries.length, (index) {
                      final s = summaries[index];
                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(s.studentName)),
                        DataCell(Center(child: Text('${s.present}'))),
                        DataCell(Center(child: Text('${s.permission}'))),
                        DataCell(Center(child: Text('${s.sick}'))),
                        DataCell(Center(child: Text('${s.absent}'))),
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
