import 'package:flutter/material.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/models/grade_model.dart';
import '../../../../data/repositories/student_repository.dart';

// Enum untuk status loading
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

  // ─── STATE UNTUK INPUT (SUBMIT) ABSENSI ──────────────────────────
  bool _isSubmittingAttendance = false;
  bool get isSubmittingAttendance => _isSubmittingAttendance;

  // Parameter sudah disesuaikan menjadi Map<String, dynamic>
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

  // ─── STATE UNTUK REKAP NILAI (GRADES) ──────────────────────────
  StudentLoadState _gradeState = StudentLoadState.initial;
  List<GradeModel> _grades = [];
  String? _gradeError;

  StudentLoadState get gradeState => _gradeState;
  List<GradeModel> get grades => _grades;
  String? get gradeError => _gradeError;

  Future<void> fetchGrades({
    required String classId,
    bool refresh = false,
    String? semester,
    String? academicYear,
  }) async {
    if (refresh) _grades = [];

    _gradeState = StudentLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getGradesRecap(
        classId: classId,
        semester: semester,
        academicYear: academicYear,
      );
      _grades = result.items;
      _gradeState = StudentLoadState.loaded;
    } catch (e) {
      _gradeError = e.toString();
      _gradeState = StudentLoadState.error;
    }
    notifyListeners();
  }
}