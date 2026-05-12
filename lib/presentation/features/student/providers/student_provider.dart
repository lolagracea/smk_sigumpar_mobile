import 'package:flutter/material.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/models/grade_model.dart';
import '../../../../data/repositories/student_repository.dart';

enum StudentLoadState { initial, loading, loaded, error }

class StudentProvider extends ChangeNotifier {
  final StudentRepository _repository;

  StudentProvider({required StudentRepository repository})
      : _repository = repository;

  // ─── STATE UNTUK REKAP ABSENSI ──────────────────────────
  StudentLoadState _attendanceState = StudentLoadState.initial;
  List<AttendanceModel> _attendances = [];
  String? _attendanceError;
  bool _hasMoreAttendances = true;
  int _attendancePage = 1;

  StudentLoadState get attendanceState => _attendanceState;
  List<AttendanceModel> get attendances => _attendances;
  String? get attendanceError => _attendanceError;
  bool get hasMoreAttendances => _hasMoreAttendances;

  Future<void> fetchAttendanceRecap({
    bool refresh = false,
    required String classId,
    String? month,
    String? year,
  }) async {
    if (refresh) {
      _attendancePage = 1;
      _attendances = [];
      _hasMoreAttendances = true;
    }

    if (!_hasMoreAttendances) return;

    _attendanceState = StudentLoadState.loading;
    _attendanceError = null;
    notifyListeners();

    try {
      final result = await _repository.getAttendanceRecap(
        classId: classId,
        month: month,
        year: year,
        page: _attendancePage,
      );

      if (refresh) {
        _attendances = result.items;
      } else {
        _attendances.addAll(result.items);
      }

      _hasMoreAttendances = result.hasNextPage;
      _attendancePage++;
      _attendanceState = StudentLoadState.loaded;
    } catch (e) {
      _attendanceError = e.toString();
      _attendanceState = StudentLoadState.error;
    }

    notifyListeners();
  }

  // ─── STATE UNTUK INPUT (SUBMIT) ABSENSI ─────────────────
  // ✅ IKUTI TEAM LEAD: Map version + rethrow di service
  bool _isSubmittingAttendance = false;
  bool get isSubmittingAttendance => _isSubmittingAttendance;

  Future<bool> submitAttendance(Map<String, dynamic> data) async {
    _isSubmittingAttendance = true;
    _attendanceError = null;
    notifyListeners();

    try {
      await _repository.submitAttendance(data);
      _isSubmittingAttendance = false;
      notifyListeners();
      return true;
    } catch (e) {
      _attendanceError = e.toString();
      _isSubmittingAttendance = false;
      notifyListeners();
      return false;
    }
  }

  // ─── STATE UNTUK REKAP NILAI (GRADES) ───────────────────
  StudentLoadState _gradeState = StudentLoadState.initial;
  List<GradeModel> _grades = [];
  String? _gradeError;

  StudentLoadState get gradeState => _gradeState;
  List<GradeModel> get grades => _grades;
  String? get gradeError => _gradeError;

  Future<void> fetchGrades({
    required String classId,
    String? semester,
    String? academicYear,
    String? mapelId,
  }) async {
    _gradeState = StudentLoadState.loading;
    notifyListeners();

    try {
      _grades = await _repository.getGradesRecap(
        classId: classId,
        semester: semester,
        academicYear: academicYear,
        mapelId: mapelId,
      );
      _gradeState = StudentLoadState.loaded;
    } catch (e) {
      _gradeError = e.toString();
      _gradeState = StudentLoadState.error;
    }
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // ─── INPUT NILAI GURU MAPEL ───────────────────────────────
  // ══════════════════════════════════════════════════════════

  StudentLoadState _assignmentState = StudentLoadState.initial;
  List<Map<String, dynamic>> _assignments = [];
  String? _assignmentError;

  StudentLoadState get assignmentState => _assignmentState;
  List<Map<String, dynamic>> get assignments => _assignments;
  String? get assignmentError => _assignmentError;

  Future<void> loadAssignments() async {
    _assignmentState = StudentLoadState.loading;
    _assignmentError = null;
    notifyListeners();

    try {
      _assignments = await _repository.getGuruMapelAssignments();
      _assignmentState = StudentLoadState.loaded;
    } catch (e) {
      _assignmentError = _parseError(e);
      _assignmentState = StudentLoadState.error;
    }
    notifyListeners();
  }

  Map<String, dynamic>? _selectedAssignment;
  List<Map<String, dynamic>> _nilaiStudents = [];
  Map<String, Map<String, dynamic>> _gradeMap = {};
  StudentLoadState _nilaiState = StudentLoadState.initial;
  String? _nilaiError;

  String _tahunAjar = '2024/2025';
  String _semester = 'ganjil';
  Map<String, int> _bobot = {
    'tugas': 20,
    'kuis': 10,
    'uts': 25,
    'uas': 30,
    'praktik': 15,
  };

  Map<String, dynamic>? get selectedAssignment => _selectedAssignment;
  List<Map<String, dynamic>> get nilaiStudents => _nilaiStudents;
  Map<String, Map<String, dynamic>> get gradeMap => _gradeMap;
  StudentLoadState get nilaiState => _nilaiState;
  String? get nilaiError => _nilaiError;
  String get tahunAjar => _tahunAjar;
  String get nilaiSemester => _semester;
  Map<String, int> get bobot => _bobot;

  Future<void> selectAssignment(Map<String, dynamic> assignment) async {
    _selectedAssignment = assignment;
    _nilaiStudents = [];
    _gradeMap = {};
    _nilaiError = null;
    notifyListeners();
    await _loadStudentsAndGrades();
  }

  Future<void> reloadNilai() async {
    if (_selectedAssignment == null) return;
    await _loadStudentsAndGrades();
  }

  Future<void> _loadStudentsAndGrades() async {
    if (_selectedAssignment == null) return;

    _nilaiState = StudentLoadState.loading;
    _nilaiError = null;
    notifyListeners();

    try {
      final kelasId = _selectedAssignment!['kelas_id'].toString();
      final mapelId =
          (_selectedAssignment!['mapel_id'] ?? _selectedAssignment!['id'])
              .toString();

      final siswaList = await _repository.getSiswaUntukInputNilai(
        kelasId: kelasId,
        mapelId: mapelId,
      );
      _nilaiStudents = siswaList;

      _gradeMap = {};
      for (final s in _nilaiStudents) {
        final id = s['id'].toString();
        _gradeMap[id] = {
          'tugas': 0.0,
          'kuis': 0.0,
          'uts': 0.0,
          'uas': 0.0,
          'praktik': 0.0,
        };
      }

      final nilaiList = await _repository.getNilaiSiswa(
        kelasId: kelasId,
        mapelId: mapelId,
        tahunAjar: _tahunAjar,
        semester: _semester,
      );

      for (final nilai in nilaiList) {
        final id = nilai['siswa_id'].toString();
        if (_gradeMap.containsKey(id)) {
          _gradeMap[id] = {
            'tugas': double.tryParse(nilai['tugas'].toString()) ?? 0.0,
            'kuis': double.tryParse(nilai['kuis'].toString()) ?? 0.0,
            'uts': double.tryParse(nilai['uts'].toString()) ?? 0.0,
            'uas': double.tryParse(nilai['uas'].toString()) ?? 0.0,
            'praktik': double.tryParse(nilai['praktik'].toString()) ?? 0.0,
          };
          if (nilai['bobot_tugas'] != null) {
            _bobot = {
              'tugas': int.tryParse(nilai['bobot_tugas'].toString()) ?? 20,
              'kuis': int.tryParse(nilai['bobot_kuis'].toString()) ?? 10,
              'uts': int.tryParse(nilai['bobot_uts'].toString()) ?? 25,
              'uas': int.tryParse(nilai['bobot_uas'].toString()) ?? 30,
              'praktik':
                  int.tryParse(nilai['bobot_praktik'].toString()) ?? 15,
            };
          }
        }
      }

      _nilaiState = StudentLoadState.loaded;
    } catch (e) {
      _nilaiError = _parseError(e);
      _nilaiState = StudentLoadState.error;
    }
    notifyListeners();
  }

  void updateGrade(String siswaId, String key, double value) {
    _gradeMap[siswaId] ??= {
      'tugas': 0.0,
      'kuis': 0.0,
      'uts': 0.0,
      'uas': 0.0,
      'praktik': 0.0,
    };
    _gradeMap[siswaId]![key] = value;
  }

  double hitungNilaiAkhir(String siswaId) {
    final g = _gradeMap[siswaId];
    if (g == null) return 0.0;
    return double.parse(
      ((g['tugas'] as num? ?? 0) * _bobot['tugas']! / 100 +
              (g['kuis'] as num? ?? 0) * _bobot['kuis']! / 100 +
              (g['uts'] as num? ?? 0) * _bobot['uts']! / 100 +
              (g['uas'] as num? ?? 0) * _bobot['uas']! / 100 +
              (g['praktik'] as num? ?? 0) * _bobot['praktik']! / 100)
          .toStringAsFixed(2),
    );
  }

  void setBobot(String key, int value) {
    _bobot[key] = value;
    notifyListeners();
  }

  int get totalBobot => _bobot.values.fold(0, (a, b) => a + b);

  void setTahunAjar(String value) {
    _tahunAjar = value;
    if (_selectedAssignment != null) _loadStudentsAndGrades();
    notifyListeners();
  }

  void setNilaiSemester(String value) {
    _semester = value;
    if (_selectedAssignment != null) _loadStudentsAndGrades();
    notifyListeners();
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<bool> saveNilai() async {
    if (_selectedAssignment == null || _nilaiStudents.isEmpty) return false;
    if (totalBobot != 100) return false;

    _isSaving = true;
    _nilaiError = null;
    notifyListeners();

    try {
      final kelasId = _selectedAssignment!['kelas_id'].toString();
      final mapelId =
          (_selectedAssignment!['mapel_id'] ?? _selectedAssignment!['id'])
              .toString();

      final dataNilai = _nilaiStudents.map((s) {
        final id = s['id'].toString();
        final g = _gradeMap[id] ?? {};
        return {
          'siswa_id': int.tryParse(id) ?? id,
          'tugas': (g['tugas'] as num?)?.toDouble() ?? 0.0,
          'kuis': (g['kuis'] as num?)?.toDouble() ?? 0.0,
          'uts': (g['uts'] as num?)?.toDouble() ?? 0.0,
          'uas': (g['uas'] as num?)?.toDouble() ?? 0.0,
          'praktik': (g['praktik'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();

      await _repository.createOrUpdateNilai(
        kelasId: kelasId,
        mapelId: mapelId,
        tahunAjar: _tahunAjar,
        semester: _semester,
        bobot: _bobot,
        dataNilai: dataNilai,
      );

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _nilaiError = _parseError(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // ─── SUBJECT ATTENDANCE (attendance_recap_screen) ─────────
  // ══════════════════════════════════════════════════════════

  StudentLoadState _scheduleState = StudentLoadState.initial;
  List<Map<String, dynamic>> _scheduleList = [];
  String? _scheduleError;

  StudentLoadState get scheduleState => _scheduleState;
  List<Map<String, dynamic>> get scheduleList => _scheduleList;
  String? get scheduleError => _scheduleError;

  Future<void> loadSchedules() async {
    _scheduleState = StudentLoadState.loading;
    _scheduleError = null;
    notifyListeners();

    try {
      _scheduleList = await _repository.getAbsensiMapelJadwal();
      _scheduleState = StudentLoadState.loaded;
    } catch (e) {
      _scheduleError = _parseError(e);
      _scheduleState = StudentLoadState.error;
    }
    notifyListeners();
  }

  Map<String, dynamic>? _selectedSchedule;
  StudentLoadState _studentListState = StudentLoadState.initial;
  List<Map<String, dynamic>> _studentList = [];
  String? _studentListError;

  Map<String, dynamic>? get selectedSchedule => _selectedSchedule;
  StudentLoadState get studentListState => _studentListState;
  List<Map<String, dynamic>> get studentList => _studentList;
  String? get studentListError => _studentListError;

  DateTime _attendanceDate = DateTime.now();
  DateTime get attendanceDate => _attendanceDate;

  void setAttendanceDate(DateTime date) {
    _attendanceDate = date;
    if (_selectedSchedule != null) _loadAttendanceForDate();
    notifyListeners();
  }

  Map<String, Map<String, dynamic>> _attendanceMap = {};
  Map<String, Map<String, dynamic>> get attendanceMap => _attendanceMap;

  StudentLoadState _recapState = StudentLoadState.initial;
  List<Map<String, dynamic>> _attendanceRecap = [];
  String? _recapError;

  StudentLoadState get recapState => _recapState;
  List<Map<String, dynamic>> get attendanceRecap => _attendanceRecap;
  String? get recapError => _recapError;

  bool _isAttendanceSaving = false;
  String? _attendanceSaveError;
  bool get isAttendanceSaving => _isAttendanceSaving;
  String? get attendanceSaveError => _attendanceSaveError;

  Future<void> selectSchedule(Map<String, dynamic> schedule) async {
    _selectedSchedule = schedule;
    _studentList = [];
    _attendanceMap = {};
    _attendanceRecap = [];
    _studentListError = null;
    _recapError = null;
    notifyListeners();
    await _loadStudentList();
    await _loadAttendanceForDate();
  }

  Future<void> _loadStudentList() async {
    if (_selectedSchedule == null) return;

    _studentListState = StudentLoadState.loading;
    _studentListError = null;
    notifyListeners();

    try {
      final jadwalId = _selectedSchedule!['id'].toString();
      _studentList = await _repository.getAbsensiMapelSiswa(
        jadwalId: jadwalId,
      );

      for (final s in _studentList) {
        final id = s['id'].toString();
        if (!_attendanceMap.containsKey(id)) {
          _attendanceMap[id] = {'status': 'hadir', 'keterangan': ''};
        }
      }

      _studentListState = StudentLoadState.loaded;
    } catch (e) {
      _studentListError = _parseError(e);
      _studentListState = StudentLoadState.error;
    }
    notifyListeners();
  }

  Future<void> _loadAttendanceForDate() async {
    if (_selectedSchedule == null) return;

    try {
      final jadwalId = _selectedSchedule!['id'].toString();
      final tanggal =
          '${_attendanceDate.year}-${_attendanceDate.month.toString().padLeft(2, '0')}-${_attendanceDate.day.toString().padLeft(2, '0')}';

      final existing = await _repository.getAbsensiMapel(
        jadwalId: jadwalId,
        tanggal: tanggal,
      );

      for (final s in _studentList) {
        final id = s['id'].toString();
        _attendanceMap[id] = {'status': 'hadir', 'keterangan': ''};
      }

      for (final a in existing) {
        final id = a['siswa_id'].toString();
        _attendanceMap[id] = {
          'status': a['status'] ?? 'hadir',
          'keterangan': a['keterangan'] ?? '',
        };
      }
    } catch (_) {
      // Belum ada data untuk tanggal ini — biarkan default hadir
    }
    notifyListeners();
  }

  Future<void> reloadStudentList() async {
    await _loadStudentList();
    await _loadAttendanceForDate();
  }

  void updateStudentStatus(String studentId, String status) {
    _attendanceMap[studentId] ??= {'status': 'hadir', 'keterangan': ''};
    _attendanceMap[studentId]!['status'] = status;
    notifyListeners();
  }

  void updateStudentNote(String studentId, String note) {
    _attendanceMap[studentId] ??= {'status': 'hadir', 'keterangan': ''};
    _attendanceMap[studentId]!['keterangan'] = note;
  }

  void setAllStudentStatus(String status) {
    for (final s in _studentList) {
      final id = s['id'].toString();
      _attendanceMap[id] ??= {'status': 'hadir', 'keterangan': ''};
      _attendanceMap[id]!['status'] = status;
    }
    notifyListeners();
  }

  Map<String, int> get attendanceStatusCounts {
    final counts = <String, int>{
      'hadir': 0,
      'izin': 0,
      'sakit': 0,
      'alpa': 0,
      'terlambat': 0,
    };
    for (final data in _attendanceMap.values) {
      final status = data['status'] as String? ?? 'hadir';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Future<bool> saveAttendance() async {
    if (_selectedSchedule == null || _studentList.isEmpty) return false;

    _isAttendanceSaving = true;
    _attendanceSaveError = null;
    notifyListeners();

    try {
      final jadwalId = _selectedSchedule!['id'];
      final tanggal =
          '${_attendanceDate.year}-${_attendanceDate.month.toString().padLeft(2, '0')}-${_attendanceDate.day.toString().padLeft(2, '0')}';

      final dataAttendance = _studentList.map((s) {
        final id = s['id'].toString();
        final a = _attendanceMap[id] ?? {'status': 'hadir', 'keterangan': ''};
        return {
          'siswa_id': int.tryParse(id) ?? id,
          'status': a['status'] ?? 'hadir',
          'keterangan': a['keterangan'] ?? '',
        };
      }).toList();

      await _repository.createAbsensiMapel(
        jadwalId: jadwalId,
        tanggal: tanggal,
        dataAbsensi: dataAttendance,
      );

      _isAttendanceSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _attendanceSaveError = _parseError(e);
      _isAttendanceSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAttendanceRecap() async {
    if (_selectedSchedule == null) return;

    _recapState = StudentLoadState.loading;
    _recapError = null;
    notifyListeners();

    try {
      final kelasId = _selectedSchedule!['kelas_id']?.toString() ?? '';
      final mapelId = _selectedSchedule!['mapel_id']?.toString() ?? '';

      _attendanceRecap = await _repository.getAbsensiMapelRekap(
        kelasId: kelasId,
        mapelId: mapelId,
      );

      _recapState = StudentLoadState.loaded;
    } catch (e) {
      _recapError = _parseError(e);
      _recapState = StudentLoadState.error;
    }
    notifyListeners();
  }

  // ─── Helper ───────────────────────────────────────────────
  String _parseError(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Network')) {
      return 'Tidak ada koneksi internet';
    }
    if (s.contains('TimeoutException')) return 'Server tidak merespon';
    if (s.contains('403')) return 'Akses ditolak';
    return s.replaceAll('Exception: ', '');
  }
}
