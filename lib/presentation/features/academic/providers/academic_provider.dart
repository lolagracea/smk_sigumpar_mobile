import 'package:flutter/material.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/student_model.dart';
import 'package:smk_sigumpar/data/models/teacher_model.dart';
import 'package:smk_sigumpar/data/repositories/academic_repository.dart';

enum AcademicLoadState { initial, loading, loaded, error }

class AcademicProvider extends ChangeNotifier {
  final AcademicRepository _repository;

  AcademicProvider({required AcademicRepository repository})
      : _repository = repository;

  // ─── Classes ─────────────────────────────────────────────

  AcademicLoadState _classState = AcademicLoadState.initial;
  List<ClassModel> _classes = [];
  String? _classError;

  AcademicLoadState get classState => _classState;
  List<ClassModel> get classes => _classes;
  String? get classError => _classError;
  bool get hasMoreClasses => false;

  Future<void> fetchClasses({bool refresh = false, String? search}) async {
    _classState = AcademicLoadState.loading;
    _classError = null;

    if (refresh) {
      _classes = [];
    }

    notifyListeners();

    try {
      final result = await _repository.getClasses(search: search);
      _classes = result;
      _classState = AcademicLoadState.loaded;
    } catch (e) {
      _classError = e.toString();
      _classState = AcademicLoadState.error;
    }

    notifyListeners();
  }

  Future<bool> createClass({
    required String namaKelas,
    required String tingkat,
    String? waliKelasId,
  }) async {
    try {
      final payload = {
        'nama_kelas': namaKelas.trim(),
        'tingkat': tingkat.trim(),
        'wali_kelas_id':
        waliKelasId != null && waliKelasId.isNotEmpty ? waliKelasId : null,
      };

      await _repository.createClass(payload);
      await fetchClasses(refresh: true);

      return true;
    } catch (e) {
      _classError = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<Map<String, dynamic>> _waliKelasUsers = [];
  bool _loadingWaliKelas = false;
  String? _waliKelasError;

  List<Map<String, dynamic>> get waliKelasUsers => _waliKelasUsers;
  bool get loadingWaliKelas => _loadingWaliKelas;
  String? get waliKelasError => _waliKelasError;

  Future<void> fetchWaliKelasUsers({String? search}) async {
    _loadingWaliKelas = true;
    _waliKelasError = null;
    notifyListeners();

    try {
      _waliKelasUsers = await _repository.getWaliKelasUsers(search: search);
    } catch (e) {
      _waliKelasError = e.toString();
      _waliKelasUsers = [];
    }

    _loadingWaliKelas = false;
    notifyListeners();
  }

  Future<bool> updateClass({
    required String id,
    required String namaKelas,
    required String tingkat,
    String? waliKelasId,
  }) async {
    try {
      final payload = {
        'nama_kelas': namaKelas.trim(),
        'tingkat': tingkat.trim(),
        'wali_kelas_id':
        waliKelasId != null && waliKelasId.isNotEmpty ? waliKelasId : null,
      };

      await _repository.updateClass(id, payload);
      await fetchClasses(refresh: true);

      return true;
    } catch (e) {
      _classError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClass(String id) async {
    try {
      await _repository.deleteClass(id);
      await fetchClasses(refresh: true);

      return true;
    } catch (e) {
      _classError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Students ─────────────────────────────────────────────

  AcademicLoadState _studentState = AcademicLoadState.initial;
  List<StudentModel> _students = [];
  String? _studentError;
  bool _hasMoreStudents = true;
  int _studentPage = 1;

  AcademicLoadState get studentState => _studentState;
  List<StudentModel> get students => _students;
  String? get studentError => _studentError;

  Future<void> fetchStudents({
    bool refresh = false,
    String? classId,
    String? search,
  }) async {
    if (refresh) {
      _studentPage = 1;
      _students = [];
      _hasMoreStudents = true;
    }

    if (!_hasMoreStudents) return;

    _studentState = AcademicLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getStudents(
        page: _studentPage,
        classId: classId,
        search: search,
      );

      _students.addAll(result.items);
      _hasMoreStudents = result.hasNextPage;
      _studentPage++;
      _studentState = AcademicLoadState.loaded;
    } catch (e) {
      _studentError = e.toString();
      _studentState = AcademicLoadState.error;
    }

    notifyListeners();
  }

  // ─── Teachers ─────────────────────────────────────────────

  AcademicLoadState _teacherState = AcademicLoadState.initial;
  List<TeacherModel> _teachers = [];
  String? _teacherError;
  bool _hasMoreTeachers = true;
  int _teacherPage = 1;

  AcademicLoadState get teacherState => _teacherState;
  List<TeacherModel> get teachers => _teachers;
  String? get teacherError => _teacherError;

  Future<void> fetchTeachers({
    bool refresh = false,
    String? search,
  }) async {
    if (refresh) {
      _teacherPage = 1;
      _teachers = [];
      _hasMoreTeachers = true;
    }

    if (!_hasMoreTeachers) return;

    _teacherState = AcademicLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getTeachers(
        page: _teacherPage,
        search: search,
      );

      _teachers.addAll(result.items);
      _hasMoreTeachers = result.hasNextPage;
      _teacherPage++;
      _teacherState = AcademicLoadState.loaded;
    } catch (e) {
      _teacherError = e.toString();
      _teacherState = AcademicLoadState.error;
    }

    notifyListeners();
  }

  // ─── Announcements ────────────────────────────────────────

  AcademicLoadState _announcementState = AcademicLoadState.initial;
  List<Map<String, dynamic>> _announcements = [];
  int _announcementPage = 1;
  bool _hasMoreAnnouncements = true;

  AcademicLoadState get announcementState => _announcementState;
  List<Map<String, dynamic>> get announcements => _announcements;

  Future<void> fetchAnnouncements({bool refresh = false}) async {
    if (refresh) {
      _announcementPage = 1;
      _announcements = [];
      _hasMoreAnnouncements = true;
    }

    if (!_hasMoreAnnouncements) return;

    _announcementState = AcademicLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getAnnouncements(
        page: _announcementPage,
      );

      _announcements.addAll(result.items);
      _hasMoreAnnouncements = result.hasNextPage;
      _announcementPage++;
      _announcementState = AcademicLoadState.loaded;
    } catch (_) {
      _announcementState = AcademicLoadState.error;
    }

    notifyListeners();
  }
}