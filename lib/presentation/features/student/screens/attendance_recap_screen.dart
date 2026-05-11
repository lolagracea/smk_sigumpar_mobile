import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  DateTime? _startDate;
  DateTime? _endDate;

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
      _fetchSummary();
    }
  }

  void _fetchSummary() {
    if (_selectedClassId == null) return;
    
    context.read<StudentProvider>().fetchAttendanceSummary(
      classId: _selectedClassId!,
      tanggalMulai: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      tanggalAkhir: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REKAP KEHADIRAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E6091),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Consumer<AcademicProvider>(
            builder: (context, provider, child) {
              return DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: InputDecoration(
                  labelText: 'Pilih Kelas',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                items: provider.classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.namaKelas))).toList(),
                onChanged: (val) {
                  setState(() => _selectedClassId = val);
                  _fetchSummary();
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                      _fetchSummary();
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(_startDate == null ? 'Mulai' : DateFormat('dd/MM/yy').format(_startDate!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                      _fetchSummary();
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(_endDate == null ? 'Akhir' : DateFormat('dd/MM/yy').format(_endDate!)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        if (provider.summaryState == StudentLoadState.loading) return const LoadingWidget();
        if (provider.summaryState == StudentLoadState.error) {
          return AppErrorWidget(message: provider.summaryError ?? 'Gagal memuat rekap', onRetry: _fetchSummary);
        }
        
        final data = provider.summaries;
        if (data.isEmpty) return const Center(child: Text('Tidak ada data kehadiran'));

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
              columns: const [
                DataColumn(label: Text('No')),
                DataColumn(label: Text('Nama Siswa')),
                DataColumn(label: Text('H')),
                DataColumn(label: Text('I')),
                DataColumn(label: Text('S')),
                DataColumn(label: Text('A')),
                DataColumn(label: Text('T')),
              ],
              rows: List.generate(data.length, (index) {
                final s = data[index];
                return DataRow(cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(Text(s.studentName)),
                  DataCell(Text('${s.present}')),
                  DataCell(Text('${s.permission}')),
                  DataCell(Text('${s.sick}')),
                  DataCell(Text('${s.absent}')),
                  DataCell(Text('${s.late}')),
                ]);
              }),
            ),
          ),
        );
      },
    );
  }
}
