import 'package:flutter/material.dart';
import 'package:smk_sigumpar/data/models/attendance_model.dart';
import 'package:smk_sigumpar/data/models/attendance_summary_model.dart';
import 'package:smk_sigumpar/data/models/grade_model.dart';
import 'package:smk_sigumpar/data/models/parenting_note_model.dart';
import 'package:smk_sigumpar/data/models/cleanliness_model.dart';
import 'package:smk_sigumpar/data/models/reflection_model.dart';
import 'package:smk_sigumpar/data/models/student_model.dart';
import 'package:smk_sigumpar/data/repositories/student_repository.dart';

enum StudentLoadState { initial, loading, loaded, error }

class StudentProvider extends ChangeNotifier {
  final StudentRepository _repository;

  StudentProvider({required StudentRepository repository})
      : _repository = repository;

  // ─── Students ─────────────────────────────────────────────
  StudentLoadState _studentsState = StudentLoadState.initial;
  List<StudentModel> _students = [];
  String? _studentsError;

  StudentLoadState get studentsState => _studentsState;
  List<StudentModel> get students => _students;
  String? get studentsError => _studentsError;

  Future<void> fetchStudents() async {
    _studentsState = StudentLoadState.loading;
    notifyListeners();

    try {
      _students = await _repository.getAllStudents();
      _studentsState = StudentLoadState.loaded;
    } catch (e) {
      _studentsError = e.toString();
      _studentsState = StudentLoadState.error;
    }
    notifyListeners();
  }

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

  // ─── Attendance Summary ──────────────────────────────────
  StudentLoadState _summaryState = StudentLoadState.initial;
  List<AttendanceSummaryModel> _summaries = [];
  String? _summaryError;

  StudentLoadState get summaryState => _summaryState;
  List<AttendanceSummaryModel> get summaries => _summaries;
  String? get summaryError => _summaryError;

  Future<void> fetchAttendanceSummary({
    required String classId,
    String? month,
    String? year,
  }) async {
    _summaryState = StudentLoadState.loading;
    notifyListeners();

    try {
      _summaries = await _repository.getAttendanceSummary(
        classId: classId,
        month: month,
        year: year,
      );
      _summaryState = StudentLoadState.loaded;
    } catch (e) {
      _summaryError = e.toString();
      _summaryState = StudentLoadState.error;
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

  // ─── Student Specific Grades ──────────────────────────────
  StudentLoadState _studentGradeState = StudentLoadState.initial;
  List<GradeModel> _studentGrades = [];
  String? _studentGradeError;

  StudentLoadState get studentGradeState => _studentGradeState;
  List<GradeModel> get studentGrades => _studentGrades;
  String? get studentGradeError => _studentGradeError;

  Future<void> fetchStudentGrades({
    required String studentId,
    String? semester,
    String? academicYear,
  }) async {
    _studentGradeState = StudentLoadState.loading;
    notifyListeners();

    try {
      _studentGrades = await _repository.getStudentGrades(
        studentId: studentId,
        semester: semester,
        academicYear: academicYear,
      );
      _studentGradeState = StudentLoadState.loaded;
    } catch (e) {
      _studentGradeError = e.toString();
      _studentGradeState = StudentLoadState.error;
    }
    notifyListeners();
  }

  // ─── Parenting Notes ──────────────────────────────────────
  StudentLoadState _parentingState = StudentLoadState.initial;
  List<ParentingNoteModel> _parentingNotes = [];
  String? _parentingError;
  bool _hasMoreParenting = true;
  int _parentingPage = 1;

  StudentLoadState get parentingState => _parentingState;
  List<ParentingNoteModel> get parentingNotes => _parentingNotes;
  String? get parentingError => _parentingError;

  Future<void> fetchParentingNotes({bool refresh = false}) async {
    if (refresh) {
      _parentingPage = 1;
      _parentingNotes = [];
      _hasMoreParenting = true;
    }
    if (!_hasMoreParenting) return;

    _parentingState = StudentLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getParentingNotes(page: _parentingPage);
      _parentingNotes.addAll(result.items);
      _hasMoreParenting = result.hasNextPage;
      _parentingPage++;
      _parentingState = StudentLoadState.loaded;
    } catch (e) {
      _parentingError = e.toString();
      _parentingState = StudentLoadState.error;
    }
    notifyListeners();
  }

  Future<void> addParentingNote(Map<String, dynamic> data) async {
    try {
      final newNote = await _repository.createParentingNote(data);
      _parentingNotes.insert(0, newNote);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Cleanliness ──────────────────────────────────────────
  StudentLoadState _cleanlinessState = StudentLoadState.initial;
  List<CleanlinessModel> _cleanlinessNotes = [];
  String? _cleanlinessError;
  bool _hasMoreCleanliness = true;
  int _cleanlinessPage = 1;

  StudentLoadState get cleanlinessState => _cleanlinessState;
  List<CleanlinessModel> get cleanlinessNotes => _cleanlinessNotes;
  String? get cleanlinessError => _cleanlinessError;

  Future<void> fetchCleanliness({bool refresh = false}) async {
    if (refresh) {
      _cleanlinessPage = 1;
      _cleanlinessNotes = [];
      _hasMoreCleanliness = true;
    }
    if (!_hasMoreCleanliness) return;

    _cleanlinessState = StudentLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getCleanlinessRecap(page: _cleanlinessPage);
      _cleanlinessNotes.addAll(result.items.map((e) => CleanlinessModel.fromJson(e)));
      _hasMoreCleanliness = result.hasNextPage;
      _cleanlinessPage++;
      _cleanlinessState = StudentLoadState.loaded;
    } catch (e) {
      _cleanlinessError = e.toString();
      _cleanlinessState = StudentLoadState.error;
    }
    notifyListeners();
  }

  Future<void> addCleanlinessNote(Map<String, dynamic> data) async {
    try {
      final result = await _repository.submitCleanliness(data);
      _cleanlinessNotes.insert(0, CleanlinessModel.fromJson(result));
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Reflections ──────────────────────────────────────────
  StudentLoadState _reflectionState = StudentLoadState.initial;
  List<ReflectionModel> _reflections = [];
  String? _reflectionError;
  bool _hasMoreReflection = true;
  int _reflectionPage = 1;

  StudentLoadState get reflectionState => _reflectionState;
  List<ReflectionModel> get reflections => _reflections;
  String? get reflectionError => _reflectionError;

  Future<void> fetchReflections({bool refresh = false}) async {
    if (refresh) {
      _reflectionPage = 1;
      _reflections = [];
      _hasMoreReflection = true;
    }
    if (!_hasMoreReflection) return;

    _reflectionState = StudentLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getHomeroomReflections(page: _reflectionPage);
      _reflections.addAll(result.items.map((e) => ReflectionModel.fromJson(e)));
      _hasMoreReflection = result.hasNextPage;
      _reflectionPage++;
      _reflectionState = StudentLoadState.loaded;
    } catch (e) {
      _reflectionError = e.toString();
      _reflectionState = StudentLoadState.error;
    }
    notifyListeners();
  }

  Future<void> addReflection(Map<String, dynamic> data) async {
    try {
      final result = await _repository.createHomeroomReflection(data);
      _reflections.insert(0, ReflectionModel.fromJson(result));
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
