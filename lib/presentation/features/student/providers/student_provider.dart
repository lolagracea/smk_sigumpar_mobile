import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smk_sigumpar/data/models/attendance_model.dart';
import 'package:smk_sigumpar/data/models/attendance_summary_model.dart';
import 'package:smk_sigumpar/data/models/grade_model.dart';
import 'package:smk_sigumpar/data/models/parenting_note_model.dart';
import 'package:smk_sigumpar/data/models/cleanliness_model.dart';
import 'package:smk_sigumpar/data/models/reflection_model.dart';
import 'package:smk_sigumpar/data/models/summons_letter_model.dart';
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

  StudentLoadState get attendanceState => _attendanceState;
  List<AttendanceModel> get attendances => _attendances;
  String? get attendanceError => _attendanceError;

  Future<void> fetchAttendance({
    required String classId,
    String? date,
  }) async {
    _attendanceState = StudentLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getAttendanceRecap(
        classId: classId,
        date: date,
      );
      _attendances = result.items;
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
    String? tanggalMulai,
    String? tanggalAkhir,
  }) async {
    _summaryState = StudentLoadState.loading;
    _summaries = [];
    notifyListeners();

    try {
      _summaries = await _repository.getAttendanceSummary(
        classId: classId,
        tanggalMulai: tanggalMulai,
        tanggalAkhir: tanggalAkhir,
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

  // ─── Parenting Notes (CRUD) ────────────────────────────────
  StudentLoadState _parentingState = StudentLoadState.initial;
  List<ParentingNoteModel> _parentingNotes = [];
  String? _parentingError;

  StudentLoadState get parentingState => _parentingState;
  List<ParentingNoteModel> get parentingNotes => _parentingNotes;
  String? get parentingError => _parentingError;

  Future<void> fetchParentingNotes({String? classId, String? studentId}) async {
    _parentingState = StudentLoadState.loading;
    notifyListeners();

    try {
      _parentingNotes = await _repository.getParentingNotes(
        classId: classId,
        studentId: studentId,
      );
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

  Future<void> deleteParentingNote(String id) async {
    try {
      await _repository.deleteParentingNote(id);
      _parentingNotes.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Cleanliness (CRUD) ──────────────────────────────────
  StudentLoadState _cleanlinessState = StudentLoadState.initial;
  List<CleanlinessModel> _cleanlinessNotes = [];
  String? _cleanlinessError;

  StudentLoadState get cleanlinessState => _cleanlinessState;
  List<CleanlinessModel> get cleanlinessNotes => _cleanlinessNotes;
  String? get cleanlinessError => _cleanlinessError;

  Future<void> fetchCleanliness({String? classId}) async {
    _cleanlinessState = StudentLoadState.loading;
    notifyListeners();

    try {
      _cleanlinessNotes = await _repository.getCleanliness(classId: classId);
      _cleanlinessState = StudentLoadState.loaded;
    } catch (e) {
      _cleanlinessError = e.toString();
      _cleanlinessState = StudentLoadState.error;
    }
    notifyListeners();
  }

  Future<void> addCleanliness(Map<String, dynamic> data, {PlatformFile? file}) async {
    try {
      final result = await _repository.createCleanliness(
        data: data,
        file: file,
      );
      _cleanlinessNotes.insert(0, result);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCleanliness(String id) async {
    try {
      await _repository.deleteCleanliness(id);
      _cleanlinessNotes.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Reflections (CRUD) ──────────────────────────────────
  StudentLoadState _reflectionState = StudentLoadState.initial;
  List<ReflectionModel> _reflections = [];
  String? _reflectionError;

  StudentLoadState get reflectionState => _reflectionState;
  List<ReflectionModel> get reflections => _reflections;
  String? get reflectionError => _reflectionError;

  Future<void> fetchReflections({String? classId}) async {
    _reflectionState = StudentLoadState.loading;
    notifyListeners();

    try {
      _reflections = await _repository.getReflections(classId: classId);
      _reflectionState = StudentLoadState.loaded;
    } catch (e) {
      _reflectionError = e.toString();
      _reflectionState = StudentLoadState.error;
    }
    notifyListeners();
  }

  Future<void> addReflection(Map<String, dynamic> data) async {
    try {
      final result = await _repository.createReflection(data);
      _reflections.insert(0, result);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReflection(String id) async {
    try {
      await _repository.deleteReflection(id);
      _reflections.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Summons Letter (CRUD) ──────────────────────────────
  StudentLoadState _summonsState = StudentLoadState.initial;
  List<SummonsLetterModel> _summonsLetters = [];
  String? _summonsError;

  StudentLoadState get summonsState => _summonsState;
  List<SummonsLetterModel> get summonsLetters => _summonsLetters;
  String? get summonsError => _summonsError;

  Future<void> fetchSummonsLetters({String? classId, String? studentId}) async {
    _summonsState = StudentLoadState.loading;
    notifyListeners();

    try {
      _summonsLetters = await _repository.getSummonsLetters(classId: classId, studentId: studentId);
      _summonsState = StudentLoadState.loaded;
    } catch (e) {
      _summonsError = e.toString();
      _summonsState = StudentLoadState.error;
    }
    notifyListeners();
  }

  Future<void> addSummonsLetter(Map<String, dynamic> data) async {
    try {
      final result = await _repository.createSummonsLetter(data);
      _summonsLetters.insert(0, result);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSummonsLetter(String id) async {
    try {
      await _repository.deleteSummonsLetter(id);
      _summonsLetters.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
