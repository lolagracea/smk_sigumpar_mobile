import 'package:flutter/material.dart';

import '../../data/models/wakil_kepsek_model.dart';
import '../../data/repositories/learning_repository.dart';

class WakilJadwalProvider extends ChangeNotifier {
  WakilJadwalProvider(this._repository);

  final LearningRepository _repository;

  // ── Jadwal Monitoring ─────────────────────────────────────────────────────
  List<JadwalModel> _jadwalList = <JadwalModel>[];
  int _totalBentrok = 0;
  bool _isLoading = false;
  String? _error;

  // Filter aktif
  String? filterHari;
  String? filterMapel;

  List<JadwalModel> get jadwalList =>
      List<JadwalModel>.unmodifiable(_jadwalList);
  int get totalBentrok => _totalBentrok;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadJadwal(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.getJadwalMonitoring(
        token,
        hari: filterHari,
        mapel: filterMapel,
      );
      _jadwalList = result['data'] as List<JadwalModel>;
      _totalBentrok = result['bentrok'] as int;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter({String? hari, String? mapel}) {
    filterHari = hari;
    filterMapel = mapel;
    notifyListeners();
  }

  // ── Rekap Per Hari ────────────────────────────────────────────────────────
  List<RekapHariModel> _rekapHari = <RekapHariModel>[];
  bool _isLoadingRekap = false;
  String? _errorRekap;

  List<RekapHariModel> get rekapHari =>
      List<RekapHariModel>.unmodifiable(_rekapHari);
  bool get isLoadingRekap => _isLoadingRekap;
  String? get errorRekap => _errorRekap;

  Future<void> loadRekapHari(String token) async {
    _isLoadingRekap = true;
    _errorRekap = null;
    notifyListeners();
    try {
      _rekapHari = await _repository.getRekapJadwalPerHari(token);
    } catch (e) {
      _errorRekap = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingRekap = false;
      notifyListeners();
    }
  }
}
