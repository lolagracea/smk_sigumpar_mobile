import 'dart:io';

import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../../data/repositories/student_repository.dart';
import '../../../common/providers/auth_provider.dart';
import '../../academic/providers/academic_provider.dart';
import '../providers/student_provider.dart';

// ─── ENTRY POINT (Wrapper Provider) ─────────────────────────
class AttendanceRecapScreen extends StatelessWidget {
  const AttendanceRecapScreen({super.key});

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
          )..loadSchedules(),
        ),
      ],
      child: const _AbsensiSiswaView(),
    );
  }
}

// ─── MAIN VIEW dengan 3 TAB ─────────────────────────────────
class _AbsensiSiswaView extends StatefulWidget {
  const _AbsensiSiswaView();

  @override
  State<_AbsensiSiswaView> createState() => _AbsensiSiswaViewState();
}

class _AbsensiSiswaViewState extends State<_AbsensiSiswaView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F7FA),
      child: Column(
        children: [
          Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor:
              isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
              indicatorColor:
              isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.edit_note_outlined), text: 'Absensi'),
                Tab(icon: Icon(Icons.history), text: 'Riwayat'),
                Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Rekap'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AbsensiInputTab(),
                _RiwayatTab(),
                _RekapTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ─── TAB 1: ABSENSI (Input) ────────────────────────────────
// ═══════════════════════════════════════════════════════════
class _AbsensiInputTab extends StatefulWidget {
  const _AbsensiInputTab();

  @override
  State<_AbsensiInputTab> createState() => _AbsensiInputTabState();
}

class _AbsensiInputTabState extends State<_AbsensiInputTab> {
  String? _selectedScheduleId;
  String? _selectedClassId;
  DateTime _selectedDate = DateTime.now();

  final Map<String, String> _attendanceMap = {};

  @override
  void initState() {
    super.initState();
    _fetchInitialSchedules();
  }

  Future<void> _fetchInitialSchedules() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      await context
          .read<AcademicProvider>()
          .fetchSchedules(teacherId: user.id);
    }
  }

  String _getFormattedDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _onScheduleChanged(String? scheduleId) {
    if (scheduleId == null) return;

    final schedules = context.read<AcademicProvider>().schedules;
    final selectedSchedule =
    schedules.firstWhere((s) => s.id?.toString() == scheduleId);

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
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitAttendance() async {
    final academicProvider = context.read<AcademicProvider>();
    final students = academicProvider.students;

    if (students.isEmpty ||
        _selectedScheduleId == null ||
        _selectedClassId == null) return;

    final payload = {
      'kelas_id': int.tryParse(_selectedClassId!) ?? 0,
      'jadwal_id': int.tryParse(_selectedScheduleId!) ?? 0,
      'tanggal': _getFormattedDate(_selectedDate),
      'data_absensi': students.map((student) {
        return {
          'siswa_id': int.tryParse(student.id.toString()) ?? 0,
          'status': _attendanceMap[student.id.toString()] ?? 'hadir',
        };
      }).toList(),
    };

    final success =
    await context.read<StudentProvider>().submitAttendance(payload);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Absensi mata pelajaran berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final error = context.read<StudentProvider>().attendanceError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal menyimpan absensi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final academicProvider = context.watch<AcademicProvider>();
    final studentProvider = context.watch<StudentProvider>();

    return RefreshIndicator(
      onRefresh: _fetchInitialSchedules,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedScheduleId,
                  dropdownColor:
                  isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Pilih Jadwal Mengajar',
                    labelStyle: TextStyle(
                        color:
                        isDark ? Colors.white54 : Colors.grey.shade600),
                    prefixIcon: Icon(Icons.schedule_rounded,
                        color: isDark ? Colors.white54 : Colors.grey),
                  ),
                  items: academicProvider.schedules.map((schedule) {
                    final formatJadwal =
                        '${schedule.hari}, ${schedule.waktuMulai}-${schedule.waktuBerakhir} | ${schedule.mataPelajaran} (${schedule.namaKelas ?? "-"})';
                    return DropdownMenuItem(
                      value: schedule.id?.toString(),
                      child: Text(formatJadwal,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
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
                      labelStyle: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade600),
                      prefixIcon: Icon(Icons.calendar_today,
                          color: isDark ? Colors.white54 : Colors.grey),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildStudentList(academicProvider, isDark)),
          if (_selectedScheduleId != null &&
              academicProvider.students.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                ),
                onPressed: studentProvider.isSubmittingAttendance
                    ? null
                    : _submitAttendance,
                icon: studentProvider.isSubmittingAttendance
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(studentProvider.isSubmittingAttendance
                    ? 'Menyimpan...'
                    : 'Simpan Absensi Mapel'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentList(AcademicProvider provider, bool isDark) {
    if (_selectedScheduleId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_rtl_rounded,
                size: 64,
                color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Pilih jadwal mengajar di atas',
                style: TextStyle(
                    color:
                    isDark ? Colors.white54 : Colors.grey.shade600)),
          ],
        ),
      );
    }

    if (provider.studentState == AcademicLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.students.isEmpty) {
      return Center(
        child: Text('Tidak ada siswa di kelas ini.',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
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
            side: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.namaLengkap,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('NISN: ${student.nisn}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusRadio('H', 'hadir', currentStatus,
                        student.id.toString(),
                        isDark ? Colors.green.shade400 : Colors.green, isDark),
                    _buildStatusRadio('S', 'sakit', currentStatus,
                        student.id.toString(),
                        isDark ? Colors.blue.shade400 : Colors.blue, isDark),
                    _buildStatusRadio('I', 'izin', currentStatus,
                        student.id.toString(),
                        isDark ? Colors.orange.shade400 : Colors.orange,
                        isDark),
                    _buildStatusRadio('A', 'alpa', currentStatus,
                        student.id.toString(),
                        isDark ? Colors.red.shade400 : Colors.red, isDark),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRadio(String label, String value, String currentStatus,
      String studentId, Color color, bool isDark) {
    final isSelected = currentStatus == value;

    return GestureDetector(
      onTap: () =>
          setState(() => _attendanceMap[studentId] = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 6),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? Colors.white12 : Colors.grey.shade100),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? Colors.white24 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.grey.shade600),
              )),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ─── TAB 2: RIWAYAT (Lihat per Tanggal) ────────────────────
// ═══════════════════════════════════════════════════════════
class _RiwayatTab extends StatefulWidget {
  const _RiwayatTab();

  @override
  State<_RiwayatTab> createState() => _RiwayatTabState();
}

class _RiwayatTabState extends State<_RiwayatTab> {
  Map<String, dynamic>? _selectedSchedule;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _absensiList = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schedules = context.read<StudentProvider>().scheduleList;
      if (schedules.isNotEmpty) {
        setState(() => _selectedSchedule = schedules.first);
        _loadAbsensi();
      }
    });
  }

  Future<void> _loadAbsensi() async {
    if (_selectedSchedule == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = sl<StudentRepository>();
      final result = await repo.getAbsensiMapel(
        jadwalId: _selectedSchedule!['id'].toString(),
        tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      setState(() => _absensiList = result);
    } catch (e) {
      setState(() => _error = 'Gagal memuat: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAbsensi();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hadir':
        return Colors.green;
      case 'sakit':
        return Colors.blue;
      case 'izin':
        return Colors.orange;
      case 'alpa':
        return Colors.red;
      case 'terlambat':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'hadir':
        return 'Hadir';
      case 'sakit':
        return 'Sakit';
      case 'izin':
        return 'Izin';
      case 'alpa':
        return 'Alpa';
      case 'terlambat':
        return 'Terlambat';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schedules = context.watch<StudentProvider>().scheduleList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Column(
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedSchedule,
                isExpanded: true,
                dropdownColor:
                isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Pilih Jadwal',
                  labelStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade700),
                  prefixIcon: const Icon(Icons.schedule),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: schedules.map((s) {
                  final label =
                      '${s['hari']} ${s['waktu_mulai']}-${s['waktu_berakhir']} | ${s['nama_mapel']} (${s['nama_kelas']})';
                  return DropdownMenuItem(
                    value: s,
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => _selectedSchedule = v);
                  _loadAbsensi();
                },
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(DateFormat('dd MMMM yyyy', 'id_ID')
                      .format(_selectedDate)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _absensiList.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off,
                    size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Belum ada absensi untuk tanggal ini',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _absensiList.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = _absensiList[i];
              final status =
              (a['status'] ?? '-').toString();
              final color = _statusColor(status);

              return Card(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: isDark
                          ? Colors.white12
                          : Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    a['nama_lengkap']?.toString() ?? '-',
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'NISN: ${a['nisn'] ?? '-'}',
                    style: TextStyle(
                        color: isDark
                            ? Colors.white54
                            : Colors.grey.shade600),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ─── TAB 3: REKAP (Filter Tanggal + Export Excel) ──────────
// ═══════════════════════════════════════════════════════════
class _RekapTab extends StatefulWidget {
  const _RekapTab();

  @override
  State<_RekapTab> createState() => _RekapTabState();
}

class _RekapTabState extends State<_RekapTab> {
  Map<String, dynamic>? _selectedSchedule;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasFetched = false;

  String _dateApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _dateDisplay(DateTime? date) {
    if (date == null) return 'Belum dipilih';
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  Future<void> _pickDate({
    required DateTime? initialValue,
    required void Function(DateTime value) onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialValue ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() => onPicked(picked));
  }

  Future<void> _tampilkanRekap() async {
    if (_selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kelas/mapel dulu')),
      );
      return;
    }

    if (_startDate != null &&
        _endDate != null &&
        _startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tanggal mulai tidak boleh > tanggal akhir')),
      );
      return;
    }

    // Trigger load via provider
    context.read<StudentProvider>().selectSchedule(_selectedSchedule!);
    await context.read<StudentProvider>().loadAttendanceRecap(
      tanggalMulai:
      _startDate != null ? _dateApi(_startDate!) : null,
      tanggalAkhir: _endDate != null ? _dateApi(_endDate!) : null,
    );
    setState(() => _hasFetched = true);
  }

  Future<void> _exportExcel() async {
    final provider = context.read<StudentProvider>();
    final recapList = provider.attendanceRecap;

    if (recapList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk export')),
      );
      return;
    }

    try {
      final excel = excel_pkg.Excel.createExcel();
      final sheet = excel['Rekap Absensi Mapel'];

      sheet.appendRow([
        excel_pkg.TextCellValue('No'),
        excel_pkg.TextCellValue('Nama Siswa'),
        excel_pkg.TextCellValue('NISN'),
        excel_pkg.TextCellValue('Kelas'),
        excel_pkg.TextCellValue('Mapel'),
        excel_pkg.TextCellValue('Tanggal Mulai'),
        excel_pkg.TextCellValue('Tanggal Akhir'),
        excel_pkg.TextCellValue('Hadir'),
        excel_pkg.TextCellValue('Izin'),
        excel_pkg.TextCellValue('Sakit'),
        excel_pkg.TextCellValue('Alpa'),
        excel_pkg.TextCellValue('Terlambat'),
        excel_pkg.TextCellValue('Total'),
        excel_pkg.TextCellValue('% Hadir'),
      ]);

      for (var i = 0; i < recapList.length; i++) {
        final row = recapList[i];
        final hadir = _toInt(row['hadir']);
        final izin = _toInt(row['izin']);
        final sakit = _toInt(row['sakit']);
        final alpa = _toInt(row['alpa']);
        final terlambat = _toInt(row['terlambat']);
        final total = _toInt(row['total'],
            fallback: hadir + izin + sakit + alpa + terlambat);
        final percent = total > 0 ? (hadir / total * 100).round() : 0;

        sheet.appendRow([
          excel_pkg.IntCellValue(i + 1),
          excel_pkg.TextCellValue(row['nama_lengkap']?.toString() ?? '-'),
          excel_pkg.TextCellValue(row['nisn']?.toString() ?? '-'),
          excel_pkg.TextCellValue(
              _selectedSchedule?['nama_kelas']?.toString() ?? '-'),
          excel_pkg.TextCellValue(
              _selectedSchedule?['nama_mapel']?.toString() ?? '-'),
          excel_pkg.TextCellValue(
              _startDate == null ? '-' : _dateApi(_startDate!)),
          excel_pkg.TextCellValue(
              _endDate == null ? '-' : _dateApi(_endDate!)),
          excel_pkg.IntCellValue(hadir),
          excel_pkg.IntCellValue(izin),
          excel_pkg.IntCellValue(sakit),
          excel_pkg.IntCellValue(alpa),
          excel_pkg.IntCellValue(terlambat),
          excel_pkg.IntCellValue(total),
          excel_pkg.TextCellValue('$percent%'),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal generate Excel')),
          );
        }
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final mapel = (_selectedSchedule?['nama_mapel'] ?? 'mapel')
          .toString()
          .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
          .toLowerCase();
      final kelas = (_selectedSchedule?['nama_kelas'] ?? 'kelas')
          .toString()
          .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
          .toLowerCase();
      final periode = _startDate == null && _endDate == null
          ? 'semua'
          : '${_startDate == null ? "awal" : _dateApi(_startDate!)}_sd_${_endDate == null ? "akhir" : _dateApi(_endDate!)}';

      final path =
          '${dir.path}/rekap_absensi_${kelas}_${mapel}_$periode.xlsx';
      await File(path).writeAsBytes(bytes, flush: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Excel berhasil dibuat'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? fallback;
  }

  Color _percentColor(double percent) {
    if (percent >= 75) return const Color(0xFF16A34A);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schedules = context.watch<StudentProvider>().scheduleList;
    final provider = context.watch<StudentProvider>();
    final recapList = provider.attendanceRecap;
    final loading = provider.recapState == StudentLoadState.loading;

    // Hitung summary
    int hadir = 0, izin = 0, sakit = 0, alpa = 0, terlambat = 0, total = 0;
    for (final r in recapList) {
      hadir += _toInt(r['hadir']);
      izin += _toInt(r['izin']);
      sakit += _toInt(r['sakit']);
      alpa += _toInt(r['alpa']);
      terlambat += _toInt(r['terlambat']);
      total += _toInt(r['total'],
          fallback: _toInt(r['hadir']) +
              _toInt(r['izin']) +
              _toInt(r['sakit']) +
              _toInt(r['alpa']) +
              _toInt(r['terlambat']));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Filter Card ─────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list,
                      color: isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Rekap Absensi Per Kelas/Mapel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedSchedule,
                isExpanded: true,
                dropdownColor:
                isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Kelas / Mapel',
                  prefixIcon: Icon(Icons.class_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: schedules.map((s) {
                  final label =
                      '${s['nama_kelas']} • ${s['nama_mapel']}';
                  return DropdownMenuItem(
                    value: s,
                    child:
                    Text(label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedSchedule = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(
                        initialValue: _startDate,
                        onPicked: (v) => _startDate = v,
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Mulai',
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffixIcon:
                          Icon(Icons.calendar_today, size: 16),
                        ),
                        child: Text(_dateDisplay(_startDate),
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(
                        initialValue: _endDate,
                        onPicked: (v) => _endDate = v,
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Akhir',
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffixIcon:
                          Icon(Icons.calendar_today, size: 16),
                        ),
                        child: Text(_dateDisplay(_endDate),
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : _tampilkanRekap,
                      icon: const Icon(Icons.bar_chart, size: 18),
                      label: Text(loading ? 'Memuat...' : 'Tampilkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: recapList.isEmpty ? null : _exportExcel,
                      icon: const Icon(Icons.table_chart, size: 18),
                      label: const Text('Export Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ─── Summary Boxes ─────────────────────────
        if (_hasFetched && recapList.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryBox(label: 'Total', value: total, color: Colors.grey),
              _SummaryBox(
                  label: 'Hadir',
                  value: hadir,
                  color: const Color(0xFF16A34A)),
              _SummaryBox(
                  label: 'Izin',
                  value: izin,
                  color: const Color(0xFFD97706)),
              _SummaryBox(
                  label: 'Sakit',
                  value: sakit,
                  color: const Color(0xFF2563EB)),
              _SummaryBox(
                  label: 'Alpa',
                  value: alpa,
                  color: const Color(0xFFDC2626)),
              _SummaryBox(
                  label: 'Terlambat',
                  value: terlambat,
                  color: const Color(0xFFEA580C)),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ─── Content ─────────────────────────
        if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (!_hasFetched)
          Padding(
            padding: const EdgeInsets.only(top: 64),
            child: Column(
              children: [
                Icon(Icons.insert_chart_outlined,
                    size: 80,
                    color: isDark ? Colors.white24 : Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Pilih kelas/mapel dan klik Tampilkan.',
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey),
                ),
              ],
            ),
          )
        else if (recapList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Column(
                children: [
                  Icon(Icons.person_off_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'Tidak ada data rekap',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...recapList.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final h = _toInt(r['hadir']);
              final iz = _toInt(r['izin']);
              final s = _toInt(r['sakit']);
              final a = _toInt(r['alpa']);
              final t = _toInt(r['terlambat']);
              final tot = _toInt(r['total'], fallback: h + iz + s + a + t);
              final percent = tot > 0 ? (h / tot * 100).round() : 0;

              return _StudentRecapCard(
                index: i,
                name: r['nama_lengkap']?.toString() ?? '-',
                nisn: r['nisn']?.toString() ?? '-',
                hadir: h,
                izin: iz,
                sakit: s,
                alpa: a,
                terlambat: t,
                total: tot,
                percent: percent,
                percentColor: _percentColor(percent.toDouble()),
                isDark: isDark,
              );
            }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ─── Helper Widgets ────────────────────────────────────────
// ═══════════════════════════════════════════════════════════
class _SummaryBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('$value',
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StudentRecapCard extends StatelessWidget {
  final int index;
  final String name;
  final String nisn;
  final int hadir, izin, sakit, alpa, terlambat, total, percent;
  final Color percentColor;
  final bool isDark;

  const _StudentRecapCard({
    required this.index,
    required this.name,
    required this.nisn,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alpa,
    required this.terlambat,
    required this.total,
    required this.percent,
    required this.percentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                const Color(0xFF2563EB).withOpacity(0.12),
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text('NISN: $nisn',
                        style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                            fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: percentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border:
                  Border.all(color: percentColor.withOpacity(0.4)),
                ),
                child: Text('$percent%',
                    style: TextStyle(
                        color: percentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniCount(
                  label: 'Hadir',
                  value: hadir,
                  color: const Color(0xFF16A34A)),
              _MiniCount(
                  label: 'Izin',
                  value: izin,
                  color: const Color(0xFFD97706)),
              _MiniCount(
                  label: 'Sakit',
                  value: sakit,
                  color: const Color(0xFF2563EB)),
              _MiniCount(
                  label: 'Alpa',
                  value: alpa,
                  color: const Color(0xFFDC2626)),
              _MiniCount(
                  label: 'Terlambat',
                  value: terlambat,
                  color: const Color(0xFFEA580C)),
              _MiniCount(label: 'Total', value: total, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniCount(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}