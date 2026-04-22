import 'package:flutter/material.dart';

import '../../data/models/wakil_kepsek_model.dart';
import '../../data/repositories/learning_repository.dart';

class WakilLaporanProvider extends ChangeNotifier {
  WakilLaporanProvider(this._repository);

  final LearningRepository _repository;

  LaporanRingkasModel? _laporan;
  bool _isLoading = false;
  String? _error;

  LaporanRingkasModel? get laporan => _laporan;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLaporan(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _laporan = await _repository.getLaporanRingkas(token);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
