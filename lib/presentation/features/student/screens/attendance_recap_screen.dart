import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../../data/repositories/student_repository.dart';
import '../../../common/providers/auth_provider.dart';
import '../../academic/providers/academic_provider.dart';
import '../providers/student_provider.dart';

// ─── WIDGET PEMBUNGKUS PROVIDER ─────────────────────────
class AttendanceRecapScreen extends StatelessWidget {
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AcademicProvider(
            repository: sl<AcademicRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StudentProvider(
            repository: sl<StudentRepository>(),
          ),
        ),
      ],
      child: const _StudentAttendanceInputView(),
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

// ─── VIEW UTAMA: INPUT ABSENSI PER MATA PELAJARAN ───────
class _StudentAttendanceInputView extends StatefulWidget {
  const _StudentAttendanceInputView();

  @override
  State<_StudentAttendanceInputView> createState() => _StudentAttendanceInputViewState();
}

class _StudentAttendanceInputViewState extends State<_StudentAttendanceInputView> {
  String? _selectedScheduleId;
  String? _selectedClassId;
  DateTime _selectedDate = DateTime.now();

  final Map<String, String> _attendanceMap = {};

  @override
  void initState() {
    super.initState();
    _fetchInitialSchedules();
  }

  // ⚠️ PERBAIKAN: Fungsi khusus untuk mengambil ulang data jadwal terbaru
  Future<void> _fetchInitialSchedules() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      await context.read<AcademicProvider>().fetchSchedules(teacherId: user.id);
    }
  }

  // ⚠️ PERBAIKAN: Format Tanggal Lokal (WIB) Absolut agar tidak tergeser oleh UTC backend
  // ⚠️ PERBAIKAN: Menggunakan garis miring (/) untuk "mengakali" bawaan JavaScript
  // "YYYY/MM/DD" akan dibaca sebagai Waktu Lokal oleh Node.js, bukan UTC.
  // ⚠️ KEMBALIKAN KE FORMAT STANDAR: Menggunakan tanda hubung (-)
  String _getFormattedLocalizerDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return "$y-$m-$d"; // Pakai tanda strip lagi
  }

  void _onScheduleChanged(String? scheduleId) {
    if (scheduleId == null) return;

    final schedules = context.read<AcademicProvider>().schedules;
    final selectedSchedule = schedules.firstWhere((s) => s.id?.toString() == scheduleId);

    setState(() {
      _selectedScheduleId = scheduleId;
      _selectedClassId = selectedSchedule.kelasId?.toString();
      _attendanceMap.clear();
    });

    if (selectedSchedule.kelasId != null) {
      context.read<AcademicProvider>().fetchStudents(
        refresh: true,
        classId: selectedSchedule.kelasId.toString(),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: Color(0xFF60A5FA), surface: Color(0xFF1E293B))
                : const ColorScheme.light(primary: Color(0xFF2563EB), surface: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitAttendance() async {
    final academicProvider = context.read<AcademicProvider>();
    final students = academicProvider.students;

    if (students.isEmpty || _selectedScheduleId == null || _selectedClassId == null) return;

    final Map<String, dynamic> payload = {
      'kelas_id': int.tryParse(_selectedClassId!) ?? 0,
      'jadwal_id': int.tryParse(_selectedScheduleId!) ?? 0,

      // Kirim format "2026/05/05"
      'tanggal': _getFormattedLocalizerDate(_selectedDate),

      'data_absensi': students.map((student) {
        return {
          'siswa_id': int.tryParse(student.id.toString()) ?? 0,
          'status': _attendanceMap[student.id.toString()] ?? 'hadir',
        };
      }).toList(),
    };

    final success = await context.read<StudentProvider>().submitAttendance(payload);

    if (!mounted) return;
    // ... (sisa kode alert dialog tetap sama di bawahnya)

    if (success) {
      showDialog(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            icon: Icon(Icons.check_circle, color: isDark ? Colors.green.shade400 : Colors.green, size: 64),
            title: Text('Berhasil', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            content: Text(
                'Absensi mata pelajaran berhasil disimpan!',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              )
            ],
          );
        },
      );
    } else {
      final error = context.read<StudentProvider>().attendanceError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal menyimpan absensi'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final academicProvider = context.watch<AcademicProvider>();
    final studentProvider = context.watch<StudentProvider>();

    return Container(
      color: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF5F7FA),
      // ⚠️ PERBAIKAN: RefreshIndicator agar data jadwal Web terbaru masuk ke Mobile
      child: RefreshIndicator(
        onRefresh: _fetchInitialSchedules,
        child: Column(
          children: [
            // ─── PENGATURAN JADWAL & TANGGAL ─────────────────────
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedScheduleId,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Pilih Jadwal Mengajar',
                      labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
                      prefixIcon: Icon(Icons.schedule_rounded, color: isDark ? Colors.white54 : Colors.grey),
                    ),
                    items: academicProvider.schedules.map((schedule) {
                      final formatJadwal = '${schedule.hari}, ${schedule.waktuMulai}-${schedule.waktuBerakhir} | ${schedule.mataPelajaran} (${schedule.namaKelas ?? "-"})';

                      return DropdownMenuItem(
                        value: schedule.id?.toString(),
                        child: Text(
                          formatJadwal,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _onScheduleChanged,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Absensi',
                        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
                        prefixIcon: Icon(Icons.calendar_today, color: isDark ? Colors.white54 : Colors.grey),
                      ),
                      child: Text(
                        "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}",
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── DAFTAR SISWA & INPUT ───────────────────────────
            Expanded(
              child: _buildStudentList(academicProvider, isDark),
            ),

            // ─── TOMBOL SUBMIT ──────────────────────────────────
            if (_selectedScheduleId != null && academicProvider.students.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4)
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: studentProvider.isSubmittingAttendance ? null : _submitAttendance,
                  icon: studentProvider.isSubmittingAttendance
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(studentProvider.isSubmittingAttendance ? 'Menyimpan...' : 'Simpan Absensi Mapel'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(AcademicProvider provider, bool isDark) {
    if (_selectedScheduleId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_rtl_rounded, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
                'Tarik layar ke bawah untuk memperbarui jadwal',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600)
            ),
          ],
        ),
      );
    }

    if (provider.studentState == AcademicLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.students.isEmpty) {
      return Center(
          child: Text(
              'Tidak ada siswa di kelas ini.',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)
          )
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = provider.students[index];
        final currentStatus = _attendanceMap[student.id.toString()] ?? 'hadir';

        return Card(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.namaLengkap,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'NISN: ${student.nisn}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.grey.shade600
                          )
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusRadio('H', 'hadir', currentStatus, student.id.toString(), isDark ? Colors.green.shade400 : Colors.green, isDark),
                    _buildStatusRadio('S', 'sakit', currentStatus, student.id.toString(), isDark ? Colors.blue.shade400 : Colors.blue, isDark),
                    _buildStatusRadio('I', 'izin', currentStatus, student.id.toString(), isDark ? Colors.orange.shade400 : Colors.orange, isDark),
                    _buildStatusRadio('A', 'alpa', currentStatus, student.id.toString(), isDark ? Colors.red.shade400 : Colors.red, isDark),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRadio(String label, String value, String currentStatus, String studentId, Color color, bool isDark) {
    final isSelected = currentStatus == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _attendanceMap[studentId] = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 6),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? Colors.white12 : Colors.grey.shade100),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white24 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }
}