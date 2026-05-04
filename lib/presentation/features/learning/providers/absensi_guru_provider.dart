import 'package:flutter/material.dart';
import '../../../../data/repositories/learning_repository.dart';

enum AbsensiGuruLoadState { initial, loading, loaded, error }

class AbsensiGuruProvider extends ChangeNotifier {
  final LearningRepository _repository;

  AbsensiGuruProvider({required LearningRepository repository})
      : _repository = repository;

  AbsensiGuruLoadState _state = AbsensiGuruLoadState.initial;
  List<Map<String, dynamic>> _absensiList = [];
  String? _error;

  AbsensiGuruLoadState get state => _state;
  List<Map<String, dynamic>> get absensiList => _absensiList;
  String? get error => _error;

  Future<void> fetchAbsensi({bool refresh = false}) async {
    if (refresh) _absensiList = [];
    _state = AbsensiGuruLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getTeacherAttendance();
      _absensiList = result.items;
      _state = AbsensiGuruLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = AbsensiGuruLoadState.error;
    }
    notifyListeners();
  }

  Future<void> submitAbsensi(Map<String, dynamic> data) async {
    _state = AbsensiGuruLoadState.loading;
    notifyListeners();
    try {
      await _repository.submitTeacherAttendance(data);
      _state = AbsensiGuruLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = AbsensiGuruLoadState.error;
    }
    notifyListeners();
  }
}
