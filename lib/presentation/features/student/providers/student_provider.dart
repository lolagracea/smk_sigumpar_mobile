import 'package:flutter/material.dart';
import 'package:smk_sigumpar/data/models/attendance_model.dart';
import 'package:smk_sigumpar/data/models/grade_model.dart';
import 'package:smk_sigumpar/data/repositories/student_repository.dart';

enum StudentLoadState { initial, loading, loaded, error }

class StudentProvider extends ChangeNotifier {
  final StudentRepository _repository;

  StudentProvider({required StudentRepository repository})
      : _repository = repository;

  // ─── Attendance ───────────────────────────────────────────
  StudentLoadState _attendanceState = StudentLoadState.initial;
  List<AttendanceModel> _attendances = [];
  String? _attendanceError;
  bool _hasMoreAttendance = true;
  int _attendancePage = 1;

  StudentLoadState get attendanceState => _attendanceState;
  List<AttendanceModel> get attendances => _attendances;
  String? get attendanceError => _attendanceError;

  Future<void> fetchAttendance({
    required String classId,
    bool refresh = false,
    String? month,
    String? year,
  }) async {
    if (refresh) {
      _attendancePage = 1;
      _attendances = [];
      _hasMoreAttendance = true;
    }
    if (!_hasMoreAttendance) return;

    _attendanceState = StudentLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getAttendanceRecap(
        classId: classId,
        page: _attendancePage,
        month: month,
        year: year,
      );
      _attendances.addAll(result.items);
      _hasMoreAttendance = result.hasNextPage;
      _attendancePage++;
      _attendanceState = StudentLoadState.loaded;
    } catch (e) {
      _attendanceError = e.toString();
      _attendanceState = StudentLoadState.error;
    }
    notifyListeners();
  }

  // ─── Grades ───────────────────────────────────────────────
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
