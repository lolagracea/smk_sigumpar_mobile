import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

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
    final id = (json['id'] ?? json['kelas_id'] ?? '').toString();

    return _ClassOption(
      id: id,
      name: (json['nama_kelas'] ??
          json['nama'] ??
          json['name'] ??
          json['kelas'] ??
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
    final id = (json['id'] ?? json['mapel_id'] ?? '').toString();

    return _SubjectOption(
      id: id,
      name: (json['nama_mapel'] ??
          json['mata_pelajaran'] ??
          json['mapel'] ??
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
    final id = (json['id'] ?? json['siswa_id'] ?? json['id_siswa'] ?? '')
        .toString();

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

class _FinalGradeRow {
  final String id;
  final String siswaId;
  final String namaSiswa;
  final String nisn;
  final String kelasId;
  final String kelasName;
  final String mapelId;
  final String mapelName;
  final double tugas;
  final double kuis;
  final double uts;
  final double uas;
  final double praktik;
  final double nilaiAkhir;
  final String predikat;
  final String catatan;

  const _FinalGradeRow({
    required this.id,
    required this.siswaId,
    required this.namaSiswa,
    required this.nisn,
    required this.kelasId,
    required this.kelasName,
    required this.mapelId,
    required this.mapelName,
    required this.tugas,
    required this.kuis,
    required this.uts,
    required this.uas,
    required this.praktik,
    required this.nilaiAkhir,
    required this.predikat,
    required this.catatan,
  });

  factory _FinalGradeRow.fromJson(
      Map<String, dynamic> json, {
        Map<String, _StudentOption> studentsById = const {},
        _ClassOption? selectedClass,
        _SubjectOption? selectedSubject,
      }) {
    final siswaId =
    (json['siswa_id'] ?? json['id_siswa'] ?? json['student_id'] ?? '')
        .toString();

    final student = studentsById[siswaId];

    final nilaiAkhir = _toDouble(
      json['nilai_akhir'] ??
          json['nilaiAkhir'] ??
          json['final_score'] ??
          json['total'],
    );

    return _FinalGradeRow(
      id: (json['id'] ?? '').toString(),
      siswaId: siswaId,
      namaSiswa: (json['nama_siswa'] ??
          json['namaSiswa'] ??
          json['nama_lengkap'] ??
          json['nama'] ??
          student?.name ??
          '-')
          .toString(),
      nisn: (json['nisn'] ?? json['nis'] ?? student?.nisn ?? '-').toString(),
      kelasId: (json['kelas_id'] ?? selectedClass?.id ?? '').toString(),
      kelasName: (json['nama_kelas'] ??
          json['kelas'] ??
          selectedClass?.name ??
          '-')
          .toString(),
      mapelId: (json['mapel_id'] ?? selectedSubject?.id ?? '').toString(),
      mapelName: (json['nama_mapel'] ??
          json['mata_pelajaran'] ??
          json['mapel'] ??
          selectedSubject?.name ??
          '-')
          .toString(),
      tugas: _toDouble(json['tugas']),
      kuis: _toDouble(json['kuis']),
      uts: _toDouble(json['uts']),
      uas: _toDouble(json['uas']),
      praktik: _toDouble(json['praktik']),
      nilaiAkhir: nilaiAkhir,
      predikat: (json['predikat'] ?? _predicateOf(nilaiAkhir)).toString(),
      catatan: (json['catatan'] ?? '-').toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }

  static String _predicateOf(double value) {
    if (value >= 90) return 'A';
    if (value >= 80) return 'B';
    if (value >= 70) return 'C';
    if (value >= 60) return 'D';
    return 'E';
  }
}

class RekapNilaiFinalKepsekScreen extends StatefulWidget {
  const RekapNilaiFinalKepsekScreen({super.key});

  @override
  State<RekapNilaiFinalKepsekScreen> createState() =>
      _RekapNilaiFinalKepsekScreenState();
}

class _RekapNilaiFinalKepsekScreenState
    extends State<RekapNilaiFinalKepsekScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loadingInitial = false;
  bool _loadingByClass = false;
  bool _loadingGrades = false;

  String? _error;

  List<_ClassOption> _classes = [];
  List<_SubjectOption> _subjects = [];
  List<_StudentOption> _students = [];
  List<_FinalGradeRow> _grades = [];

  String? _selectedClassId;
  String? _selectedSubjectId;
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
            .map(
              (item) => _ClassOption.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .where((item) => item.id.isNotEmpty)
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = _messageFromError(
          e,
          fallback: 'Gagal memuat data kelas',
        );
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
      _subjects = [];
      _students = [];
      _grades = [];
      _selectedSubjectId = null;
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
            .map(
              (item) => _SubjectOption.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .where((item) => item.id.isNotEmpty)
            .toList();

        _students = studentRows
            .whereType<Map>()
            .map(
              (item) => _StudentOption.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .where((item) => item.id.isNotEmpty)
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = _messageFromError(
          e,
          fallback: 'Gagal memuat mapel atau siswa pada kelas terpilih',
        );
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

  Future<void> _loadGrades() async {
    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      _showSnack('Pilih kelas terlebih dahulu');
      return;
    }

    if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
      _showSnack('Pilih mata pelajaran terlebih dahulu');
      return;
    }

    setState(() {
      _loadingGrades = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();

      final response = await dio.get(
        ApiEndpoints.studentGrades,
        queryParameters: {
          'kelas_id': _selectedClassId,
          'mapel_id': _selectedSubjectId,
        },
      );

      final rows = _extractList(response.data);
      final studentsById = {
        for (final student in _students) student.id: student,
      };

      setState(() {
        _grades = rows
            .whereType<Map>()
            .map(
              (item) => _FinalGradeRow.fromJson(
            Map<String, dynamic>.from(item),
            studentsById: studentsById,
            selectedClass: _selectedClass,
            selectedSubject: _selectedSubject,
          ),
        )
            .where((item) => item.siswaId.isNotEmpty)
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = _messageFromError(
          e,
          fallback: 'Gagal memuat rekap nilai final',
        );
        _grades = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingGrades = false;
        });
      }
    }
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

  List<_FinalGradeRow> get _filteredGrades {
    final keyword = _search.trim().toLowerCase();

    if (keyword.isEmpty) return _grades;

    return _grades.where((item) {
      return item.namaSiswa.toLowerCase().contains(keyword) ||
          item.nisn.toLowerCase().contains(keyword);
    }).toList();
  }

  int get _totalSiswa {
    return _filteredGrades.length;
  }

  double get _averageScore {
    final rows = _filteredGrades;

    if (rows.isEmpty) return 0;

    final total = rows.fold<double>(
      0,
          (sum, item) => sum + item.nilaiAkhir,
    );

    return total / rows.length;
  }

  int get _countTuntas {
    return _filteredGrades.where((item) => item.nilaiAkhir >= 70).length;
  }

  int get _countBelumTuntas {
    return _filteredGrades.where((item) => item.nilaiAkhir < 70).length;
  }

  String _messageFromError(
      Object error, {
        required String fallback,
      }) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }

    return fallback;
  }

  void _resetFilter() {
    setState(() {
      _selectedSubjectId = null;
      _grades = [];
      _search = '';
      _searchController.clear();
    });
  }

  Color _scoreColor(double value) {
    if (value >= 90) return const Color(0xFF16A34A);
    if (value >= 80) return const Color(0xFF2563EB);
    if (value >= 70) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  String _predicateOf(double value) {
    if (value >= 90) return 'A';
    if (value >= 80) return 'B';
    if (value >= 70) return 'C';
    if (value >= 60) return 'D';
    return 'E';
  }

  String _formatScore(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  Future<void> _exportExcel() async {
    final rows = _filteredGrades;

    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      _showSnack('Pilih kelas terlebih dahulu');
      return;
    }

    if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
      _showSnack('Pilih mata pelajaran terlebih dahulu');
      return;
    }

    if (rows.isEmpty) {
      _showSnack('Tidak ada data nilai untuk diexport');
      return;
    }

    final excel = excel_pkg.Excel.createExcel();
    final sheet = excel['Rekap Nilai Final'];

    sheet.appendRow([
      excel_pkg.TextCellValue('No'),
      excel_pkg.TextCellValue('Nama Siswa'),
      excel_pkg.TextCellValue('NISN'),
      excel_pkg.TextCellValue('Kelas'),
      excel_pkg.TextCellValue('Mata Pelajaran'),
      excel_pkg.TextCellValue('Tugas'),
      excel_pkg.TextCellValue('Kuis'),
      excel_pkg.TextCellValue('UTS'),
      excel_pkg.TextCellValue('UAS'),
      excel_pkg.TextCellValue('Praktik'),
      excel_pkg.TextCellValue('Nilai Akhir'),
      excel_pkg.TextCellValue('Predikat'),
      excel_pkg.TextCellValue('Keterangan'),
    ]);

    for (var i = 0; i < rows.length; i++) {
      final item = rows[i];

      sheet.appendRow([
        excel_pkg.IntCellValue(i + 1),
        excel_pkg.TextCellValue(item.namaSiswa),
        excel_pkg.TextCellValue(item.nisn),
        excel_pkg.TextCellValue(item.kelasName),
        excel_pkg.TextCellValue(item.mapelName),
        excel_pkg.DoubleCellValue(item.tugas),
        excel_pkg.DoubleCellValue(item.kuis),
        excel_pkg.DoubleCellValue(item.uts),
        excel_pkg.DoubleCellValue(item.uas),
        excel_pkg.DoubleCellValue(item.praktik),
        excel_pkg.DoubleCellValue(item.nilaiAkhir),
        excel_pkg.TextCellValue(
          item.predikat.isEmpty ? _predicateOf(item.nilaiAkhir) : item.predikat,
        ),
        excel_pkg.TextCellValue(item.catatan),
      ]);
    }

    final bytes = excel.encode();

    if (bytes == null) {
      _showSnack('Gagal membuat file Excel');
      return;
    }

    final kelasName = (_selectedClass?.name ?? 'kelas')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '-')
        .toLowerCase();

    final mapelName = (_selectedSubject?.name ?? 'mapel')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '-')
        .toLowerCase();

    await FileSaver.instance.saveFile(
      name: 'rekap-nilai-final-$kelasName-$mapelName',
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    _showSnack('File Excel berhasil dibuat');
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

  Future<void> _refresh() async {
    await _loadClasses();

    if (_selectedClassId != null && _selectedClassId!.isNotEmpty) {
      await _loadSubjectsAndStudents(_selectedClassId!);
    }

    if (_selectedClassId != null &&
        _selectedClassId!.isNotEmpty &&
        _selectedSubjectId != null &&
        _selectedSubjectId!.isNotEmpty) {
      await _loadGrades();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = _filteredGrades;

    return Container(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F7FA),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 12),
            _buildFilterCard(isDark),
            const SizedBox(height: 12),
            if (_selectedClassId != null || _selectedSubjectId != null) ...[
              _buildActiveFilterCard(isDark),
              const SizedBox(height: 12),
            ],
            _buildSummaryGrid(isDark),
            const SizedBox(height: 12),
            if (_error != null)
              _buildError()
            else if (_loadingInitial || _loadingByClass || _loadingGrades)
              const Padding(
                padding: EdgeInsets.only(top: 56),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_selectedClassId == null)
                _buildEmpty(
                  icon: Icons.school_outlined,
                  message: 'Pilih kelas terlebih dahulu.',
                )
              else if (_selectedSubjectId == null)
                  _buildEmpty(
                    icon: Icons.menu_book_outlined,
                    message: 'Pilih mata pelajaran terlebih dahulu.',
                  )
                else if (rows.isEmpty)
                    _buildEmpty(
                      icon: Icons.assignment_outlined,
                      message: 'Belum ada nilai final untuk kelas dan mapel ini.',
                    )
                  else
                    ...rows.asMap().entries.map(
                          (entry) => _buildGradeCard(
                        index: entry.key,
                        item: entry.value,
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
            'Rekap Nilai Final',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pilih kelas dan mata pelajaran untuk melihat nilai final siswa.',
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
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 13,
            ),
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
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              labelText: 'Mata Pelajaran',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
            items: _subjects.map((subject) {
              return DropdownMenuItem(
                value: subject.id,
                child: Text(
                  subject.name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _selectedClassId == null
                ? null
                : (value) {
              setState(() {
                _selectedSubjectId = value;
                _grades = [];
              });
            },
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
                  onPressed: _loadingGrades ? null : _loadGrades,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(_loadingGrades ? 'Memuat...' : 'Tampilkan'),
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
        'Filter aktif: ${_selectedClass?.name ?? '-'} • ${_selectedSubject?.name ?? '-'}',
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
        _SummaryBox(
          label: 'Total Siswa',
          value: '$_totalSiswa',
          color: Colors.grey,
        ),
        _SummaryBox(
          label: 'Rata-rata',
          value: _formatScore(_averageScore),
          color: _scoreColor(_averageScore),
        ),
        _SummaryBox(
          label: 'Tuntas',
          value: '$_countTuntas',
          color: const Color(0xFF16A34A),
        ),
        _SummaryBox(
          label: 'Belum',
          value: '$_countBelumTuntas',
          color: const Color(0xFFDC2626),
        ),
      ],
    );
  }

  Widget _buildGradeCard({
    required int index,
    required _FinalGradeRow item,
    required bool isDark,
  }) {
    final color = _scoreColor(item.nilaiAkhir);
    final predikat =
    item.predikat.isEmpty ? _predicateOf(item.nilaiAkhir) : item.predikat;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.12),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: color,
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
                      item.namaSiswa,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NISN: ${item.nisn}',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatScore(item.nilaiAkhir),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      predikat,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniScore(label: 'Tugas', value: item.tugas),
              _MiniScore(label: 'Kuis', value: item.kuis),
              _MiniScore(label: 'UTS', value: item.uts),
              _MiniScore(label: 'UAS', value: item.uas),
              _MiniScore(label: 'Praktik', value: item.praktik),
            ],
          ),
          if (item.catatan.isNotEmpty && item.catatan != '-') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Catatan: ${item.catatan}',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 10),
          Text(
            _error ?? 'Terjadi kesalahan',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _selectedClassId == null ? _loadClasses : _loadGrades,
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
  final String value;
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
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 11),
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
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  final String label;
  final double value;

  const _MiniScore({
    required this.label,
    required this.value,
  });

  String _formatScore(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  Color _color(double value) {
    if (value >= 90) return const Color(0xFF16A34A);
    if (value >= 80) return const Color(0xFF2563EB);
    if (value >= 70) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(value);

    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            _formatScore(value),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
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