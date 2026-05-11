import 'package:flutter/material.dart';
import 'package:smk_sigumpar/data/repositories/vocational_repository.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/student_model.dart';
import 'package:smk_sigumpar/data/models/pkl_location_model.dart';
import 'package:smk_sigumpar/data/models/pkl_progress_model.dart';
import 'package:smk_sigumpar/data/models/pkl_grade_model.dart';

enum VocationalLoadState { initial, loading, loaded, error }

class VocationalProvider extends ChangeNotifier {
  final VocationalRepository _repository;

  VocationalProvider({required VocationalRepository repository})
      : _repository = repository;

  VocationalLoadState _state = VocationalLoadState.initial;
  String? _error;

  // Scout
  List<Map<String, dynamic>> _scoutClasses = [];

  // PKL Classes & Students
  List<ClassModel> _pklClasses = [];
  List<StudentModel> _pklStudents = [];
  ClassModel? _selectedPklClass;
  StudentModel? _selectedPklStudent;

  // PKL Location Reports
  List<PklLocationModel> _pklLocationReports = [];

  // PKL Progress Reports
  List<PklProgressModel> _pklProgressReports = [];

  // PKL Grades
  List<PklGradeModel> _pklGrades = [];

  // Getters
  VocationalLoadState get state => _state;
  String? get error => _error;

  List<Map<String, dynamic>> get scoutClasses => _scoutClasses;

  List<ClassModel> get pklClasses => _pklClasses;
  List<StudentModel> get pklStudents => _pklStudents;
  ClassModel? get selectedPklClass => _selectedPklClass;
  StudentModel? get selectedPklStudent => _selectedPklStudent;

  List<PklLocationModel> get pklLocationReports => _pklLocationReports;
  List<PklProgressModel> get pklProgressReports => _pklProgressReports;
  List<PklGradeModel> get pklGrades => _pklGrades;

  // Scout
  Future<void> fetchScoutClasses({bool refresh = false}) async {
    if (refresh) _scoutClasses = [];
    _state = VocationalLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getScoutClasses();
      _scoutClasses = result.items;
      _state = VocationalLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
    }
    notifyListeners();
  }

  // PKL Classes
  Future<void> fetchPklClasses({bool refresh = false, String? search}) async {
    if (refresh) _pklClasses = [];
    _state = VocationalLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getPklClasses(search: search);
      _pklClasses = result.items;
      _state = VocationalLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
    }
    notifyListeners();
  }

  // PKL Students by class
  Future<void> fetchPklStudents({
    bool refresh = false,
    required String classId,
    String? search,
  }) async {
    if (refresh) _pklStudents = [];
    _state = VocationalLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getPklStudents(
        classId: classId,
        search: search,
      );
      _pklStudents = result.items;
      _state = VocationalLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
    }
    notifyListeners();
  }

  void selectPklClass(ClassModel kelas) {
    _selectedPklClass = kelas;
    _selectedPklStudent = null;
    _pklStudents = [];
    notifyListeners();
  }

  void selectPklStudent(StudentModel siswa) {
    _selectedPklStudent = siswa;
    notifyListeners();
  }

  void clearSelection() {
    _selectedPklClass = null;
    _selectedPklStudent = null;
    _pklStudents = [];
    notifyListeners();
  }

  // PKL Location Reports
  Future<void> fetchPklLocationReports({
    bool refresh = false,
    String? classId,
    String? studentId,
  }) async {
    if (refresh) _pklLocationReports = [];
    _state = VocationalLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getPklLocationReports(
        classId: classId,
        studentId: studentId,
      );
      _pklLocationReports = result.items;
      _state = VocationalLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
    }
    notifyListeners();
  }

  Future<PklLocationModel> submitPklLocationReport(
      Map<String, dynamic> data) async {
    _state = VocationalLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.submitPklLocationReport(data);
      _pklLocationReports.insert(0, result);
      _state = VocationalLoadState.loaded;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
      notifyListeners();
      rethrow;
    }
  }

  // PKL Progress Reports
  Future<void> fetchPklProgressReports({
    bool refresh = false,
    String? classId,
    String? studentId,
  }) async {
    if (refresh) _pklProgressReports = [];
    _state = VocationalLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getPklProgressReports(
        classId: classId,
        studentId: studentId,
      );
      _pklProgressReports = result.items;
      _state = VocationalLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
    }
    notifyListeners();
  }

  // PKL Grades
  Future<void> fetchPklGrades({
    bool refresh = false,
    String? classId,
    String? studentId,
  }) async {
    if (refresh) _pklGrades = [];
    _state = VocationalLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getPklGrades(
        classId: classId,
        studentId: studentId,
      );
      _pklGrades = result.items;
      _state = VocationalLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
    }
    notifyListeners();
  }

  Future<void> submitPklGrade(Map<String, dynamic> data) async {
    _state = VocationalLoadState.loading;
    notifyListeners();
    try {
      await _repository.submitPklGrade(data);
      _pklGrades.insert(
          0,
          PklGradeModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            siswaId: data['siswa_id']?.toString() ?? '',
            namaSiswa: data['nama_siswa']?.toString() ?? '',
            kelasId: data['kelas_id']?.toString() ?? '',
            namaKelas: data['nama_kelas']?.toString() ?? '',
            pklLokasiId: data['pkl_lokasi_id']?.toString(),
            aspekTeknis: data['aspek_teknis']?.toString(),
            aspekNonTeknis: data['aspek_non_teknis']?.toString(),
            aspekKedisiplinan: data['aspek_kedisiplinan']?.toString(),
            aspekKerjasama: data['aspek_kerjasama']?.toString(),
            aspekInisiatif: data['aspek_inisiatif']?.toString(),
            nilai: data['nilai']?.toString(),
            deskripsi: data['deskripsi']?.toString(),
            createdAt: DateTime.now().toIso8601String(),
          ));
      _state = VocationalLoadState.loaded;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<PklProgressModel> submitPklProgressReport(
      Map<String, dynamic> data) async {
    _state = VocationalLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.submitPklProgressReport(data);
      _pklProgressReports.insert(0, result);
      _state = VocationalLoadState.loaded;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
      notifyListeners();
      rethrow;
    }
  }
}
