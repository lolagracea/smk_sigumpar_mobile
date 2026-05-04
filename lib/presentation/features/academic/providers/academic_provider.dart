import 'package:flutter/material.dart';
import 'package:smk_sigumpar/core/network/api_response.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/student_model.dart';
import 'package:smk_sigumpar/data/models/teacher_model.dart';
import 'package:smk_sigumpar/data/models/user_search_model.dart';
import 'package:smk_sigumpar/data/repositories/academic_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smk_sigumpar/data/models/arsip_surat_model.dart';
import 'package:smk_sigumpar/data/models/mapel_assignment_model.dart';
import 'package:smk_sigumpar/data/models/schedule_model.dart';
import 'package:smk_sigumpar/data/models/subject_model.dart';

enum AcademicLoadState { initial, loading, loaded, error }

class AcademicProvider extends ChangeNotifier {
  final AcademicRepository _repository;

  AcademicProvider({required AcademicRepository repository})
      : _repository = repository;

  // ─── Shared Error Parser (Biar Catch-mu rapi) ──────────────
  String _parseError(Object error) {
    final errorStr = error.toString();
    if (errorStr.contains('SocketException')) return 'Tidak ada koneksi internet';
    if (errorStr.contains('TimeoutException')) return 'Server tidak merespon';
    return errorStr.replaceAll('Exception: ', '');
  }

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

  Future<void> fetchClasses({bool refresh = false, String? search}) async {
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
      final result = await _repository.getClasses(page: _classPage, search: search);
      if (refresh) _classes = result.items;
      else _classes.addAll(result.items);
      _hasMoreClasses = result.hasNextPage;
      _classPage++;
      _classState = AcademicLoadState.loaded;
    } catch (e) {
      _classError = _parseError(e);
      _classState = AcademicLoadState.error;
    }
    notifyListeners();
  }

  Future<List<UserSearchModel>> searchWaliKelas(String query) async {
    try { return await _repository.searchWaliKelas(query); } catch (_) { return []; }
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
      _classError = _parseError(e);
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
  bool get hasMoreStudents => _hasMoreStudents;

  Future<void> fetchStudents({bool refresh = false, String? classId, String? search}) async {
    if (refresh) {
      _studentPage = 1;
      _students = [];
      _hasMoreStudents = true;
    }
    if (!_hasMoreStudents) return;

    _studentState = AcademicLoadState.loading;
    _studentError = null;
    notifyListeners();

    try {
      final result = await _repository.getStudents(page: _studentPage, classId: classId, search: search);
      if (refresh) _students = result.items;
      else _students.addAll(result.items);
      _hasMoreStudents = result.hasNextPage;
      _studentPage++;
      _studentState = AcademicLoadState.loaded;
    } catch (e) {
      _studentError = _parseError(e);
      _studentState = AcademicLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> createStudent({required String nisn, required String namaLengkap, required String kelasId}) async {
    try {
      _studentError = null;
      notifyListeners();
      await _repository.createStudent({'nisn': nisn, 'nama_lengkap': namaLengkap, 'kelas_id': kelasId});
      await fetchStudents(refresh: true);
      return true;
    } catch (e) {
      _studentError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStudent({required String id, required String nisn, required String namaLengkap, required String kelasId}) async {
    try {
      _studentError = null;
      notifyListeners();
      await _repository.updateStudent(id, {'nisn': nisn, 'nama_lengkap': namaLengkap, 'kelas_id': kelasId});
      await fetchStudents(refresh: true);
      return true;
    } catch (e) {
      _studentError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent({required String id}) async {
    try {
      _studentError = null;
      notifyListeners();
      await _repository.deleteStudent(id);
      await fetchStudents(refresh: true);
      return true;
    } catch (e) {
      _studentError = _parseError(e);
      notifyListeners();
      return false;
    }
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

  Future<void> fetchTeachers({bool refresh = false, String? search}) async {
    if (refresh) {
      _teacherPage = 1;
      _teachers = [];
      _hasMoreTeachers = true;
    }
    if (!_hasMoreTeachers) return;
    _teacherState = AcademicLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getTeachers(page: _teacherPage, search: search);
      _teachers.addAll(result.items);
      _hasMoreTeachers = result.hasNextPage;
      _teacherPage++;
      _teacherState = AcademicLoadState.loaded;
    } catch (e) {
      _teacherError = _parseError(e);
      _teacherState = AcademicLoadState.error;
    }
    notifyListeners();
  }

  // ─── Announcements ────────────────────────────────────────
  AcademicLoadState _announcementState = AcademicLoadState.initial;
  List<Map<String, dynamic>> _announcements = [];
  String? _announcementError;
  int _announcementPage = 1;
  bool _hasMoreAnnouncements = true;

  AcademicLoadState get announcementState => _announcementState;
  List<Map<String, dynamic>> get announcements => _announcements;
  String? get announcementError => _announcementError;
  bool get hasMoreAnnouncements => _hasMoreAnnouncements;

  Future<void> fetchAnnouncements({bool refresh = false}) async {
    if (refresh) {
      _announcementPage = 1;
      _announcements = [];
      _hasMoreAnnouncements = true;
    }
    if (!_hasMoreAnnouncements) return;
    _announcementState = AcademicLoadState.loading;
    _announcementError = null;
    notifyListeners();

    try {
      final result = await _repository.getAnnouncements(page: _announcementPage);
      if (refresh) _announcements = result.items;
      else _announcements.addAll(result.items);
      _hasMoreAnnouncements = result.hasNextPage;
      _announcementPage++;
      _announcementState = AcademicLoadState.loaded;
    } catch (e) {
      _announcementError = _parseError(e);
      _announcementState = AcademicLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> createAnnouncement({required String judul, required String isi}) async {
    try {
      _announcementError = null;
      notifyListeners();
      await _repository.createAnnouncement({'judul': judul, 'isi': isi});
      await fetchAnnouncements(refresh: true);
      return true;
    } catch (e) {
      _announcementError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAnnouncement({required String id, required String judul, required String isi}) async {
    try {
      _announcementError = null;
      notifyListeners();
      await _repository.updateAnnouncement(id, {'judul': judul, 'isi': isi});
      await fetchAnnouncements(refresh: true);
      return true;
    } catch (e) {
      _announcementError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAnnouncement({required String id}) async {
    try {
      _announcementError = null;
      notifyListeners();
      await _repository.deleteAnnouncement(id);
      await fetchAnnouncements(refresh: true);
      return true;
    } catch (e) {
      _announcementError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ─── Schedules / Jadwal Mengajar ─────────────────────────
  AcademicLoadState _scheduleState = AcademicLoadState.initial;
  List<ScheduleModel> _schedules = [];
  String? _scheduleError;

  AcademicLoadState get scheduleState => _scheduleState;
  List<ScheduleModel> get schedules => _schedules;
  String? get scheduleError => _scheduleError;

  Future<void> fetchSchedules({String? classId, String? teacherId}) async {
    _scheduleState = AcademicLoadState.loading;
    _scheduleError = null;
    notifyListeners();
    try {
      _schedules = await _repository.getSchedules(classId: classId, teacherId: teacherId);
      _scheduleState = AcademicLoadState.loaded;
    } catch (e) {
      _scheduleError = _parseError(e);
      _scheduleState = AcademicLoadState.error;
    }
    notifyListeners();
  }

  Future<List<UserSearchModel>> searchGuruMapel(String query) async {
    try { return await _repository.searchGuruMapel(query); } catch (_) { return []; }
  }

  Future<List<MapelAssignmentModel>> getMapelByGuru(String guruId) async {
    try { return await _repository.getMapelByGuru(guruId); } catch (_) { return []; }
  }

  Future<bool> createSchedule({
    required String guruId,
    required String guruNama,
    required String kelasId,
    required String mapelId,
    required String mataPelajaran,
    required String hari,
    required String waktuMulai,
    required String waktuBerakhir,
  }) async {
    try {
      _scheduleError = null;
      notifyListeners();
      await _repository.createSchedule({
        'guru_id': guruId,
        'guru_nama': guruNama,
        'kelas_id': kelasId,
        'mapel_id': mapelId,
        'mata_pelajaran': mataPelajaran,
        'hari': hari,
        'waktu_mulai': waktuMulai,
        'waktu_berakhir': waktuBerakhir,
      });
      await fetchSchedules(classId: kelasId);
      return true;
    } catch (e) {
      _scheduleError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSchedule({
    required String id,
    required String guruId,
    required String guruNama,
    required String kelasId,
    required String mapelId,
    required String mataPelajaran,
    required String hari,
    required String waktuMulai,
    required String waktuBerakhir,
  }) async {
    try {
      _scheduleError = null;
      notifyListeners();
      await _repository.updateSchedule(id, {
        'guru_id': guruId,
        'guru_nama': guruNama,
        'kelas_id': kelasId,
        'mapel_id': mapelId,
        'mata_pelajaran': mataPelajaran,
        'hari': hari,
        'waktu_mulai': waktuMulai,
        'waktu_berakhir': waktuBerakhir,
      });
      await fetchSchedules(classId: kelasId);
      return true;
    } catch (e) {
      _scheduleError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSchedule({required String id}) async {
    try {
      _scheduleError = null;
      notifyListeners();
      await _repository.deleteSchedule(id);
      await fetchSchedules();
      return true;
    } catch (e) {
      _scheduleError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ─── Letters / Arsip Surat ──────────────────────────────
  AcademicLoadState _letterState = AcademicLoadState.initial;
  List<ArsipSuratModel> _letters = [];
  String? _letterError;
  bool _hasMoreLetters = true;
  int _letterPage = 1;

  AcademicLoadState get letterState => _letterState;
  List<ArsipSuratModel> get letters => _letters;
  String? get letterError => _letterError;
  bool get hasMoreLetters => _hasMoreLetters;

  Future<void> fetchLetters({bool refresh = false}) async {
    if (refresh) { _letterPage = 1; _letters = []; _hasMoreLetters = true; }
    if (!_hasMoreLetters) return;

    _letterState = AcademicLoadState.loading;
    _letterError = null;
    notifyListeners();

    try {
      final result = await _repository.getLetters(page: _letterPage);
      if (refresh) _letters = result.items;
      else _letters.addAll(result.items);
      _hasMoreLetters = result.hasNextPage;
      _letterPage++;
      _letterState = AcademicLoadState.loaded;
    } catch (e) {
      _letterError = _parseError(e);
      _letterState = AcademicLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> createLetter({required String nomorSurat, required PlatformFile file}) async {
    try {
      _letterError = null;
      notifyListeners();
      await _repository.createLetter(nomorSurat: nomorSurat, file: file);
      await fetchLetters(refresh: true);
      return true;
    } catch (e) {
      _letterError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLetter({required String id, required String nomorSurat, PlatformFile? file}) async {
    try {
      _letterError = null;
      notifyListeners();
      await _repository.updateLetter(id: id, nomorSurat: nomorSurat, file: file);
      await fetchLetters(refresh: true);
      return true;
    } catch (e) {
      _letterError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLetter({required String id}) async {
    try {
      _letterError = null;
      notifyListeners();
      await _repository.deleteLetter(id);
      await fetchLetters(refresh: true);
      return true;
    } catch (e) {
      _letterError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ─── Subjects / Mata Pelajaran ──────────────────────────
  AcademicLoadState _subjectState = AcademicLoadState.initial;
  List<SubjectModel> _subjects = [];
  String? _subjectError;
  bool _hasMoreSubjects = true;
  int _subjectPage = 1;

  AcademicLoadState get subjectState => _subjectState;
  List<SubjectModel> get subjects => _subjects;
  String? get subjectError => _subjectError;
  bool get hasMoreSubjects => _hasMoreSubjects;

  Future<void> fetchSubjects({bool refresh = false, String? classId, String? teacherId, String? search}) async {
    if (refresh) { _subjectPage = 1; _subjects = []; _hasMoreSubjects = true; }
    if (!_hasMoreSubjects) return;

    _subjectState = AcademicLoadState.loading;
    _subjectError = null;
    notifyListeners();

    try {
      final result = await _repository.getSubjects(page: _subjectPage, classId: classId, teacherId: teacherId, search: search);
      if (refresh) _subjects = result.items;
      else _subjects.addAll(result.items);
      _hasMoreSubjects = result.hasNextPage;
      _subjectPage++;
      _subjectState = AcademicLoadState.loaded;
    } catch (e) {
      _subjectError = _parseError(e);
      _subjectState = AcademicLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> createSubject({
    required String namaMapel,
    required String kelasId,
    required String guruMapelId,
    required String guruMapelNama,
  }) async {
    try {
      _subjectError = null;
      notifyListeners();
      await _repository.createSubject({
        'nama_mapel': namaMapel,
        'kelas_id': kelasId,
        'guru_mapel_id': guruMapelId,
        'guru_mapel_nama': guruMapelNama,
      });
      await fetchSubjects(refresh: true);
      return true;
    } catch (e) {
      _subjectError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSubject({
    required String id,
    required String namaMapel,
    required String kelasId,
    required String guruMapelId,
    required String guruMapelNama,
  }) async {
    try {
      _subjectError = null;
      notifyListeners();
      await _repository.updateSubject(id, {
        'nama_mapel': namaMapel,
        'kelas_id': kelasId,
        'guru_mapel_id': guruMapelId,
        'guru_mapel_nama': guruMapelNama,
      });
      await fetchSubjects(refresh: true);
      return true;
    } catch (e) {
      _subjectError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSubject({required String id}) async {
    try {
      _subjectError = null;
      notifyListeners();
      await _repository.deleteSubject(id);
      await fetchSubjects(refresh: true);
      return true;
    } catch (e) {
      _subjectError = _parseError(e);
      notifyListeners();
      return false;
    }
  }
}