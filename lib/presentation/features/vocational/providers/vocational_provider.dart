import 'package:flutter/material.dart';
import 'package:smk_sigumpar/data/repositories/vocational_repository.dart';

enum VocationalLoadState { initial, loading, loaded, error }

class VocationalProvider extends ChangeNotifier {
  final VocationalRepository _repository;

  VocationalProvider({required VocationalRepository repository})
      : _repository = repository;

  VocationalLoadState _state = VocationalLoadState.initial;
  List<Map<String, dynamic>> _scoutClasses = [];
  List<Map<String, dynamic>> _pklReports = [];
  List<Map<String, dynamic>> _pklGrades = [];
  String? _error;

  VocationalLoadState get state => _state;
  List<Map<String, dynamic>> get scoutClasses => _scoutClasses;
  List<Map<String, dynamic>> get pklReports => _pklReports;
  List<Map<String, dynamic>> get pklGrades => _pklGrades;
  String? get error => _error;

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

  Future<void> fetchPklLocationReports({bool refresh = false}) async {
    if (refresh) _pklReports = [];
    _state = VocationalLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getPklLocationReports();
      _pklReports = result.items;
      _state = VocationalLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
    }
    notifyListeners();
  }

  Future<void> fetchPklGrades({bool refresh = false}) async {
    if (refresh) _pklGrades = [];
    _state = VocationalLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getPklGrades();
      _pklGrades = result.items;
      _state = VocationalLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> submitPklGrade(Map<String, dynamic> data) async {
    try {
      _state = VocationalLoadState.loading;
      notifyListeners();
      await _repository.submitPklGrade(data);
      _state = VocationalLoadState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _state = VocationalLoadState.error;
      notifyListeners();
      return false;
    }
  }
}
