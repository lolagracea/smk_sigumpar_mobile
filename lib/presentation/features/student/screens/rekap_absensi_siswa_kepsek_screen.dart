import 'dart:io';

import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

class _ClassOption {
  final String id;
  final String name;

  const _ClassOption({
    required this.id,
    required this.name,
  });

  factory _ClassOption.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();

    return _ClassOption(
      id: id,
      name: (json['nama_kelas'] ??
          json['nama'] ??
          json['name'] ??
          'Kelas $id')
          .toString(),
    );
  }
}

class _SubjectOption {
  final String id;
  final String name;

  const _SubjectOption({
    required this.id,
    required this.name,
  });

  factory _SubjectOption.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();

    return _SubjectOption(
      id: id,
      name: (json['nama_mapel'] ??
          json['mata_pelajaran'] ??
          json['nama'] ??
          json['name'] ??
          'Mapel $id')
          .toString(),
    );
  }
}

class _StudentOption {
  final String id;
  final String name;
  final String nisn;

  const _StudentOption({
    required this.id,
    required this.name,
    required this.nisn,
  });

  factory _StudentOption.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();

    return _StudentOption(
      id: id,
      name: (json['nama_lengkap'] ??
          json['nama_siswa'] ??
          json['nama'] ??
          json['name'] ??
          '-')
          .toString(),
      nisn: (json['nisn'] ?? json['nis'] ?? '-').toString(),
    );
  }
}

class _AttendanceRecapRow {
  final String siswaId;
  final int hadir;
  final int izin;
  final int sakit;
  final int alpa;
  final int terlambat;
  final int total;

  const _AttendanceRecapRow({
    required this.siswaId,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alpa,
    required this.terlambat,
    required this.total,
  });

  factory _AttendanceRecapRow.zero(String siswaId) {
    return _AttendanceRecapRow(
      siswaId: siswaId,
      hadir: 0,
      izin: 0,
      sakit: 0,
      alpa: 0,
      terlambat: 0,
      total: 0,
    );
  }

  factory _AttendanceRecapRow.fromJson(Map<String, dynamic> json) {
    final hadir = _toInt(json['hadir']);
    final izin = _toInt(json['izin']);
    final sakit = _toInt(json['sakit']);
    final alpa = _toInt(json['alpa']);
    final terlambat = _toInt(json['terlambat']);

    return _AttendanceRecapRow(
      siswaId: (json['siswa_id'] ?? json['id_siswa'] ?? json['student_id'] ?? '')
          .toString(),
      hadir: hadir,
      izin: izin,
      sakit: sakit,
      alpa: alpa,
      terlambat: terlambat,
      total: _toInt(json['total'], fallback: hadir + izin + sakit + alpa + terlambat),
    );
  }

  double get percentHadir {
    if (total <= 0) return 0;
    return (hadir / total) * 100;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? fallback;
  }
}

class RekapAbsensiSiswaKepsekScreen extends StatefulWidget {
  const RekapAbsensiSiswaKepsekScreen({super.key});

  @override
  State<RekapAbsensiSiswaKepsekScreen> createState() =>
      _RekapAbsensiSiswaKepsekScreenState();
}

class _RekapAbsensiSiswaKepsekScreenState
    extends State<RekapAbsensiSiswaKepsekScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loadingInitial = false;
  bool _loadingByClass = false;
  bool _loadingRecap = false;

  String? _error;

  List<_ClassOption> _classes = [];
  List<_SubjectOption> _subjects = [];
  List<_StudentOption> _students = [];
  List<_AttendanceRecapRow> _recaps = [];

  String? _selectedClassId;
  String? _selectedSubjectId;
  DateTime? _startDate;
  DateTime? _endDate;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;

    if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) return raw['data'] as List;

      if (raw['data'] is Map<String, dynamic>) {
        final data = raw['data'] as Map<String, dynamic>;

        if (data['data'] is List) return data['data'] as List;
        if (data['items'] is List) return data['items'] as List;
        if (data['rows'] is List) return data['rows'] as List;
      }

      if (raw['items'] is List) return raw['items'] as List;
      if (raw['rows'] is List) return raw['rows'] as List;
    }

    return [];
  }

  String _dateApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _dateDisplay(DateTime? date) {
    if (date == null) return 'Belum dipilih';
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loadingInitial = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();
      final response = await dio.get(ApiEndpoints.classes);
      final rows = _extractList(response.data);

      setState(() {
        _classes = rows
            .whereType<Map>()
            .map((item) => _ClassOption.fromJson(
          Map<String, dynamic>.from(item),
        ))
            .where((item) => item.id.isNotEmpty)
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data kelas';
        _classes = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingInitial = false;
        });
      }
    }
  }

  Future<void> _loadSubjectsAndStudents(String classId) async {
    setState(() {
      _loadingByClass = true;
      _error = null;
      _selectedSubjectId = null;
      _subjects = [];
      _students = [];
      _recaps = [];
      _search = '';
      _searchController.clear();
    });

    try {
      final dio = sl<DioClient>();

      final responses = await Future.wait([
        dio.get(
          ApiEndpoints.subjects,
          queryParameters: {'kelas_id': classId},
        ),
        dio.get(
          ApiEndpoints.students,
          queryParameters: {'kelas_id': classId},
        ),
      ]);

      final subjectRows = _extractList(responses[0].data);
      final studentRows = _extractList(responses[1].data);

      setState(() {
        _subjects = subjectRows
            .whereType<Map>()
            .map((item) => _SubjectOption.fromJson(
          Map<String, dynamic>.from(item),
        ))
            .where((item) => item.id.isNotEmpty)
            .toList();

        _students = studentRows
            .whereType<Map>()
            .map((item) => _StudentOption.fromJson(
          Map<String, dynamic>.from(item),
        ))
            .where((item) => item.id.isNotEmpty)
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat mapel atau siswa pada kelas terpilih';
        _subjects = [];
        _students = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingByClass = false;
        });
      }
    }
  }

  Future<void> _loadRecap() async {
    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      _showSnack('Pilih kelas terlebih dahulu');
      return;
    }

    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      _showSnack('Tanggal mulai tidak boleh lebih besar dari tanggal akhir');
      return;
    }

    setState(() {
      _loadingRecap = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();

      final response = await dio.get(
        ApiEndpoints.kepsekRekapStudentAttendance,
        queryParameters: {
          'kelas_id': _selectedClassId,
          if (_selectedSubjectId != null && _selectedSubjectId!.isNotEmpty)
            'mapel_id': _selectedSubjectId,
          if (_startDate != null) 'tanggal_mulai': _dateApi(_startDate!),
          if (_endDate != null) 'tanggal_akhir': _dateApi(_endDate!),
        },
      );

      final rows = _extractList(response.data);

      setState(() {
        _recaps = rows
            .whereType<Map>()
            .map((item) => _AttendanceRecapRow.fromJson(
          Map<String, dynamic>.from(item),
        ))
            .where((item) => item.siswaId.isNotEmpty)
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat rekap absensi siswa';
        _recaps = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingRecap = false;
        });
      }
    }
  }

  List<_StudentOption> get _filteredStudents {
    final keyword = _search.trim().toLowerCase();

    if (keyword.isEmpty) return _students;

    return _students.where((student) {
      return student.name.toLowerCase().contains(keyword) ||
          student.nisn.toLowerCase().contains(keyword);
    }).toList();
  }

  Map<String, _AttendanceRecapRow> get _recapMap {
    return {
      for (final recap in _recaps) recap.siswaId: recap,
    };
  }

  _AttendanceRecapRow _getRecapByStudent(String siswaId) {
    return _recapMap[siswaId] ?? _AttendanceRecapRow.zero(siswaId);
  }

  int get _summaryHadir {
    return _filteredStudents.fold(
      0,
          (sum, student) => sum + _getRecapByStudent(student.id).hadir,
    );
  }

  int get _summaryIzin {
    return _filteredStudents.fold(
      0,
          (sum, student) => sum + _getRecapByStudent(student.id).izin,
    );
  }

  int get _summarySakit {
    return _filteredStudents.fold(
      0,
          (sum, student) => sum + _getRecapByStudent(student.id).sakit,
    );
  }

  int get _summaryAlpa {
    return _filteredStudents.fold(
      0,
          (sum, student) => sum + _getRecapByStudent(student.id).alpa,
    );
  }

  int get _summaryTerlambat {
    return _filteredStudents.fold(
      0,
          (sum, student) => sum + _getRecapByStudent(student.id).terlambat,
    );
  }

  int get _summaryTotal {
    return _filteredStudents.fold(
      0,
          (sum, student) => sum + _getRecapByStudent(student.id).total,
    );
  }

  _ClassOption? get _selectedClass {
    for (final item in _classes) {
      if (item.id == _selectedClassId) return item;
    }
    return null;
  }

  _SubjectOption? get _selectedSubject {
    for (final item in _subjects) {
      if (item.id == _selectedSubjectId) return item;
    }
    return null;
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

    setState(() {
      onPicked(picked);
    });
  }

  void _resetFilter() {
    setState(() {
      _selectedSubjectId = null;
      _startDate = null;
      _endDate = null;
      _search = '';
      _recaps = [];
      _searchController.clear();
    });
  }

  Future<void> _exportExcel() async {
    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      _showSnack('Pilih kelas terlebih dahulu');
      return;
    }

    final students = _filteredStudents;

    if (students.isEmpty) {
      _showSnack('Tidak ada data siswa untuk diexport');
      return;
    }

    final excel = excel_pkg.Excel.createExcel();
    final sheet = excel['Rekap Absensi Siswa'];

    sheet.appendRow([
      excel_pkg.TextCellValue('No'),
      excel_pkg.TextCellValue('Nama Siswa'),
      excel_pkg.TextCellValue('NISN'),
      excel_pkg.TextCellValue('Kelas'),
      excel_pkg.TextCellValue('Mata Pelajaran'),
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

    for (var i = 0; i < students.length; i++) {
      final student = students[i];
      final recap = _getRecapByStudent(student.id);

      sheet.appendRow([
        excel_pkg.IntCellValue(i + 1),
        excel_pkg.TextCellValue(student.name),
        excel_pkg.TextCellValue(student.nisn),
        excel_pkg.TextCellValue(_selectedClass?.name ?? '-'),
        excel_pkg.TextCellValue(_selectedSubject?.name ?? 'Semua Mapel'),
        excel_pkg.TextCellValue(_startDate == null ? '-' : _dateApi(_startDate!)),
        excel_pkg.TextCellValue(_endDate == null ? '-' : _dateApi(_endDate!)),
        excel_pkg.IntCellValue(recap.hadir),
        excel_pkg.IntCellValue(recap.izin),
        excel_pkg.IntCellValue(recap.sakit),
        excel_pkg.IntCellValue(recap.alpa),
        excel_pkg.IntCellValue(recap.terlambat),
        excel_pkg.IntCellValue(recap.total),
        excel_pkg.TextCellValue('${recap.percentHadir.round()}%'),
      ]);
    }

    final bytes = excel.encode();

    if (bytes == null) {
      _showSnack('Gagal membuat file Excel');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();

    final kelasName = (_selectedClass?.name ?? 'kelas')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '-')
        .toLowerCase();

    final periode = _startDate == null && _endDate == null
        ? 'semua-tanggal'
        : '${_startDate == null ? "awal" : _dateApi(_startDate!)}_sd_${_endDate == null ? "akhir" : _dateApi(_endDate!)}';

    final path = '${dir.path}/rekap-absensi-siswa-$kelasName-$periode.xlsx';

    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    _showSnack('File Excel berhasil dibuat');
    await OpenFilex.open(path);
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _percentColor(double value) {
    if (value >= 75) return const Color(0xFF16A34A);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final students = _filteredStudents;

    return Container(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F7FA),
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadClasses();

          if (_selectedClassId != null && _selectedClassId!.isNotEmpty) {
            await _loadSubjectsAndStudents(_selectedClassId!);
            await _loadRecap();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 12),
            _buildFilterCard(isDark),
            const SizedBox(height: 12),
            if (_selectedClassId != null)
              _buildActiveFilterCard(isDark),
            if (_selectedClassId != null)
              const SizedBox(height: 12),
            _buildSummaryGrid(isDark),
            const SizedBox(height: 12),
            if (_error != null)
              _buildError()
            else if (_loadingInitial || _loadingByClass || _loadingRecap)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_selectedClassId == null)
                _buildEmpty(
                  icon: Icons.school_outlined,
                  message: 'Pilih kelas terlebih dahulu.',
                )
              else if (students.isEmpty)
                  _buildEmpty(
                    icon: Icons.person_search_outlined,
                    message: 'Tidak ada siswa yang cocok.',
                  )
                else
                  ...students.asMap().entries.map(
                        (entry) => _buildStudentCard(
                      index: entry.key,
                      student: entry.value,
                      recap: _getRecapByStudent(entry.value.id),
                      isDark: isDark,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rekap Absensi Siswa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pantau rekap absensi siswa per kelas, semua mapel, atau mapel tertentu.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedClassId,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: _loadingInitial ? 'Memuat kelas...' : 'Kelas',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.class_outlined),
            ),
            items: _classes.map((kelas) {
              return DropdownMenuItem(
                value: kelas.id,
                child: Text(
                  kelas.name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _loadingInitial
                ? null
                : (value) async {
              setState(() {
                _selectedClassId = value;
              });

              if (value != null && value.isNotEmpty) {
                await _loadSubjectsAndStudents(value);
              }
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedSubjectId,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: const InputDecoration(
              labelText: 'Mata Pelajaran',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('Semua Mapel'),
              ),
              ..._subjects.map((subject) {
                return DropdownMenuItem(
                  value: subject.id,
                  child: Text(
                    subject.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: _selectedClassId == null
                ? null
                : (value) {
              setState(() {
                _selectedSubjectId =
                value == null || value.isEmpty ? null : value;
              });
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Tanggal Mulai',
                  value: _dateDisplay(_startDate),
                  onTap: () {
                    _pickDate(
                      initialValue: _startDate,
                      onPicked: (value) => _startDate = value,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DatePickerField(
                  label: 'Tanggal Akhir',
                  value: _dateDisplay(_endDate),
                  onTap: () {
                    _pickDate(
                      initialValue: _endDate,
                      onPicked: (value) => _endDate = value,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search Siswa',
              hintText: 'Cari nama siswa atau NISN...',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _search = value;
              });
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetFilter,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loadingRecap ? null : _loadRecap,
                  icon: const Icon(Icons.bar_chart),
                  label: Text(_loadingRecap ? 'Memuat...' : 'Tampilkan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exportExcel,
              icon: const Icon(Icons.table_chart),
              label: const Text('Export Excel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.blue.shade900 : Colors.blue.shade100,
        ),
      ),
      child: Text(
        'Filter aktif: ${_selectedClass?.name ?? '-'} • ${_selectedSubject?.name ?? 'Semua Mata Pelajaran'}',
        style: TextStyle(
          color: isDark ? Colors.blue.shade100 : Colors.blue.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryBox(label: 'Total', value: _summaryTotal, color: Colors.grey),
        _SummaryBox(
          label: 'Hadir',
          value: _summaryHadir,
          color: const Color(0xFF16A34A),
        ),
        _SummaryBox(
          label: 'Izin',
          value: _summaryIzin,
          color: const Color(0xFFD97706),
        ),
        _SummaryBox(
          label: 'Sakit',
          value: _summarySakit,
          color: const Color(0xFF2563EB),
        ),
        _SummaryBox(
          label: 'Alpa',
          value: _summaryAlpa,
          color: const Color(0xFFDC2626),
        ),
        _SummaryBox(
          label: 'Terlambat',
          value: _summaryTerlambat,
          color: const Color(0xFFEA580C),
        ),
      ],
    );
  }

  Widget _buildStudentCard({
    required int index,
    required _StudentOption student,
    required _AttendanceRecapRow recap,
    required bool isDark,
  }) {
    final percent = recap.percentHadir;
    final percentColor = _percentColor(percent);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NISN: ${student.nisn}',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: percentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: percentColor.withOpacity(0.4)),
                ),
                child: Text(
                  '${percent.round()}%',
                  style: TextStyle(
                    color: percentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniCount(label: 'Hadir', value: recap.hadir, color: const Color(0xFF16A34A)),
              _MiniCount(label: 'Izin', value: recap.izin, color: const Color(0xFFD97706)),
              _MiniCount(label: 'Sakit', value: recap.sakit, color: const Color(0xFF2563EB)),
              _MiniCount(label: 'Alpa', value: recap.alpa, color: const Color(0xFFDC2626)),
              _MiniCount(label: 'Terlambat', value: recap.terlambat, color: const Color(0xFFEA580C)),
              _MiniCount(label: 'Total', value: recap.total, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Terjadi kesalahan',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (_selectedClassId == null) {
                _loadClasses();
              } else {
                _loadRecap();
              }
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Icon(icon, size: 60, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 102,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
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

  const _MiniCount({
    required this.label,
    required this.value,
    required this.color,
  });

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
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}