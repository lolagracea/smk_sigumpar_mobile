import 'package:flutter/material.dart';
import 'package:smk_sigumpar/data/repositories/vocational_repository.dart';

enum VocationalLoadState { initial, loading, loaded, error }

/// ─────────────────────────────────────────────────────────────
/// VocationalProvider — state management untuk modul PRAMUKA
///
/// Mengelola:
/// - Daftar kelas/regu pramuka
/// - Absensi pramuka
/// - Laporan kegiatan pramuka
/// ─────────────────────────────────────────────────────────────
class VocationalProvider extends ChangeNotifier {
  final VocationalRepository _repository;

  VocationalProvider({required VocationalRepository repository})
      : _repository = repository;

  // ── State ──────────────────────────────────────────────────
  VocationalLoadState _state = VocationalLoadState.initial;
  String? _error;

  // ── Scout Classes (Regu/Kelas Pramuka) ─────────────────────
  List<Map<String, dynamic>> _scoutClasses = [];

  // ── Scout Attendance (Absensi Pramuka) ─────────────────────
  List<Map<String, dynamic>> _scoutAttendance = [];

  // ── Scout Activity Reports (Laporan Kegiatan) ───────────────
  List<Map<String, dynamic>> _scoutReports = [];

  // ── Getters ────────────────────────────────────────────────
  VocationalLoadState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == VocationalLoadState.loading;
  bool get hasError => _state == VocationalLoadState.error;

  List<Map<String, dynamic>> get scoutClasses => _scoutClasses;
  List<Map<String, dynamic>> get scoutAttendance => _scoutAttendance;
  List<Map<String, dynamic>> get scoutReports => _scoutReports;

  // ── Fetch Scout Classes (Kelas Pramuka) ─────────────────────
  Future<void> fetchScoutClasses({bool refresh = false}) async {
    if (refresh) _scoutClasses = [];
    _setState(VocationalLoadState.loading);

    try {
      final result = await _repository.getScoutClasses();
      _scoutClasses = result.items;
      _setState(VocationalLoadState.loaded);
    } catch (e) {
      _error = _parseError(e);
      _setState(VocationalLoadState.error);
    }
  }

  // ── Fetch Scout Attendance (Absensi Pramuka) ─────────────────
  Future<void> fetchScoutAttendance({bool refresh = false, String? classId}) async {
    if (refresh) _scoutAttendance = [];
    _setState(VocationalLoadState.loading);

    try {
      final result = await _repository.getScoutAttendance(classId: classId);
      _scoutAttendance = result.items;
      _setState(VocationalLoadState.loaded);
    } catch (e) {
      _error = _parseError(e);
      _setState(VocationalLoadState.error);
    }
  }

  // ── Submit Scout Attendance ──────────────────────────────────
  Future<bool> submitScoutAttendance(Map<String, dynamic> data) async {
    _setState(VocationalLoadState.loading);
    try {
      await _repository.submitScoutAttendance(data);
      _setState(VocationalLoadState.loaded);
      return true;
    } catch (e) {
      _error = _parseError(e);
      _setState(VocationalLoadState.error);
      return false;
    }
  }

  // ── Fetch Scout Reports (Laporan Kegiatan) ────────────────────
  Future<void> fetchScoutReports({bool refresh = false}) async {
    if (refresh) _scoutReports = [];
    _setState(VocationalLoadState.loading);

    try {
      final result = await _repository.getScoutReports();
      _scoutReports = result.items;
      _setState(VocationalLoadState.loaded);
    } catch (e) {
      _error = _parseError(e);
      _setState(VocationalLoadState.error);
    }
  }

  // ── Create Scout Report ───────────────────────────────────────
  Future<bool> createScoutReport(Map<String, dynamic> data) async {
    _setState(VocationalLoadState.loading);
    try {
      final newReport = await _repository.createScoutReport(data);
      _scoutReports = [newReport, ..._scoutReports];
      _setState(VocationalLoadState.loaded);
      return true;
    } catch (e) {
      _error = _parseError(e);
      _setState(VocationalLoadState.error);
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setState(VocationalLoadState state) {
    _state = state;
    notifyListeners();
  }

  String _parseError(Object e) {
    return e.toString().replaceAll('NetworkExceptions: ', '');
  }
}