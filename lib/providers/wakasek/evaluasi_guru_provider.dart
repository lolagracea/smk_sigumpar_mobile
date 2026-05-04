import 'package:flutter/material.dart';

import '../../data/models/wakasek_models.dart';
import '../../data/repositories/wakasek_repository.dart';

class EvaluasiGuruProvider extends ChangeNotifier {
  EvaluasiGuruProvider(this._repository);

  final WakasekRepository _repository;

  List<EvaluasiGuruModel> _items = <EvaluasiGuruModel>[];
  List<GuruMapelModel> _guruList = <GuruMapelModel>[];
  bool _isLoading = false;
  bool _isLoadingGuru = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<EvaluasiGuruModel> get items =>
      List<EvaluasiGuruModel>.unmodifiable(_items);
  List<GuruMapelModel> get guruList =>
      List<GuruMapelModel>.unmodifiable(_guruList);
  bool get isLoading => _isLoading;
  bool get isLoadingGuru => _isLoadingGuru;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> load({required String token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repository.getEvaluasiGuru(token: token);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGuruList({required String token}) async {
    _isLoadingGuru = true;
    notifyListeners();

    try {
      _guruList = await _repository.getGuruMapelList(token: token);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingGuru = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String guruId,
    required String namaGuru,
    String? mapel,
    String? semester,
    int? skor,
    String? predikat,
    String? catatan,
    required String token,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createEvaluasiGuru(
        guruId: guruId,
        namaGuru: namaGuru,
        mapel: mapel,
        semester: semester,
        skor: skor,
        predikat: predikat,
        catatan: catatan,
        token: token,
      );
      await load(token: token);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}