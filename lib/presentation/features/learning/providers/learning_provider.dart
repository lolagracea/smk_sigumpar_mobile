import 'package:flutter/material.dart';
import 'package:smk_sigumpar/data/repositories/learning_repository.dart';

enum LearningLoadState { initial, loading, loaded, error }

class LearningProvider extends ChangeNotifier {
  final LearningRepository _repository;

  LearningProvider({required LearningRepository repository})
      : _repository = repository;

  // ─── Teacher Attendance ───────────────────────────────────
  LearningLoadState _attendanceState = LearningLoadState.initial;
  List<Map<String, dynamic>> _teacherAttendances = [];
  String? _attendanceError;

  LearningLoadState get attendanceState => _attendanceState;
  List<Map<String, dynamic>> get teacherAttendances => _teacherAttendances;

  Future<void> fetchTeacherAttendance({bool refresh = false, String? date}) async {
    if (refresh) _teacherAttendances = [];

    _attendanceState = LearningLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getTeacherAttendance(date: date);
      _teacherAttendances = result.items;
      _attendanceState = LearningLoadState.loaded;
    } catch (e) {
      _attendanceError = e.toString();
      _attendanceState = LearningLoadState.error;
    }
    notifyListeners();
  }

  // ─── Teaching Notes ───────────────────────────────────────
  LearningLoadState _notesState = LearningLoadState.initial;
  List<Map<String, dynamic>> _teachingNotes = [];

  LearningLoadState get notesState => _notesState;
  List<Map<String, dynamic>> get teachingNotes => _teachingNotes;

  Future<void> fetchTeachingNotes({bool refresh = false}) async {
    if (refresh) _teachingNotes = [];

    _notesState = LearningLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getTeachingNotes();
      _teachingNotes = result.items;
      _notesState = LearningLoadState.loaded;
    } catch (e) {
      _notesState = LearningLoadState.error;
    }
    notifyListeners();
  }

  // ─── Learning Devices ─────────────────────────────────────
  LearningLoadState _deviceState = LearningLoadState.initial;
  List<Map<String, dynamic>> _learningDevices = [];

  LearningLoadState get deviceState => _deviceState;
  List<Map<String, dynamic>> get learningDevices => _learningDevices;

  Future<void> fetchLearningDevices({bool refresh = false}) async {
    if (refresh) _learningDevices = [];

    _deviceState = LearningLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getLearningDevices();
      _learningDevices = result.items;
      _deviceState = LearningLoadState.loaded;
    } catch (e) {
      _deviceState = LearningLoadState.error;
    }
    notifyListeners();
  }
}
