import 'package:flutter/material.dart';
import 'package:smk_sigumpar/core/network/api_response.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/student_model.dart';
import 'package:smk_sigumpar/data/models/teacher_model.dart';
import 'package:smk_sigumpar/data/models/user_search_model.dart';
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
  bool _hasMoreClasses = true;
  int _classPage = 1;

  AcademicLoadState get classState => _classState;
  List<ClassModel> get classes => _classes;
  String? get classError => _classError;
  bool get hasMoreClasses => _hasMoreClasses;

  Future<void> fetchClasses({
    bool refresh = false,
    String? search,
  }) async {
    if (refresh) {
      _classPage = 1;
      _classes = [];
      _hasMoreClasses = true;
    }

    if (!_hasMoreClasses) return;

    _classState = AcademicLoadState.loading;
    _classError = null;
    notifyListeners();

    try {
      final result = await _repository.getClasses(
        page: _classPage,
        search: search,
      );

      if (refresh) {
        _classes = result.items;
      } else {
        _classes.addAll(result.items);
      }

      _hasMoreClasses = result.hasNextPage;
      _classPage++;
      _classState = AcademicLoadState.loaded;
    } catch (e) {
      _classError = e.toString();
      _classState = AcademicLoadState.error;
    }

    notifyListeners();
  }

  Future<List<UserSearchModel>> searchWaliKelas(String query) async {
    try {
      return await _repository.searchWaliKelas(query);
    } catch (_) {
      return [];
    }
  }

  Future<bool> createClass({
    required String namaKelas,
    required String tingkat,
    required String waliKelasId,
    required String waliKelasNama,
  }) async {
    try {
      _classError = null;
      notifyListeners();

      await _repository.createClass({
        'nama_kelas': namaKelas,
        'tingkat': tingkat,
        'wali_kelas_id': waliKelasId,
        'wali_kelas_nama': waliKelasNama,
      });

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

  Future<void> fetchAnnouncements({
    bool refresh = false,
  }) async {
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
    } catch (e) {
      _announcementState = AcademicLoadState.error;
    }

    notifyListeners();
  }
}