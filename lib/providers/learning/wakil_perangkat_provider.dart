import 'package:flutter/material.dart';

import '../../data/models/wakil_kepsek_model.dart';
import '../../data/repositories/learning_repository.dart';

class WakilPerangkatProvider extends ChangeNotifier {
  WakilPerangkatProvider(this._repository);

  final LearningRepository _repository;

  // ── Daftar Guru ───────────────────────────────────────────────────────────
  List<GuruPerangkatModel> _daftarGuru = <GuruPerangkatModel>[];
  bool _isLoadingDaftar = false;
  String? _errorDaftar;

  List<GuruPerangkatModel> get daftarGuru =>
      List<GuruPerangkatModel>.unmodifiable(_daftarGuru);
  bool get isLoadingDaftar => _isLoadingDaftar;
  String? get errorDaftar => _errorDaftar;

  Future<void> loadDaftarGuru(String token) async {
    _isLoadingDaftar = true;
    _errorDaftar = null;
    notifyListeners();
    try {
      _daftarGuru = await _repository.getDaftarGuruPerangkat(token);
    } catch (e) {
      _errorDaftar = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingDaftar = false;
      notifyListeners();
    }
  }

  // ── Detail Guru ───────────────────────────────────────────────────────────
  GuruPerangkatDetailModel? _detail;
  bool _isLoadingDetail = false;
  String? _errorDetail;

  GuruPerangkatDetailModel? get detail => _detail;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get errorDetail => _errorDetail;

  Future<void> loadDetailGuru(String token, int guruId) async {
    _isLoadingDetail = true;
    _errorDetail = null;
    _detail = null;
    notifyListeners();
    try {
      _detail = await _repository.getPerangkatByGuru(token, guruId);
    } catch (e) {
      _errorDetail = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // ── CRUD Perangkat ────────────────────────────────────────────────────────
  bool _isSaving = false;
  String? _saveError;

  bool get isSaving => _isSaving;
  String? get saveError => _saveError;

  Future<bool> createPerangkat(
    String token,
    int guruId,
    String namaPerangkat,
    String jenis,
    String status, {
    String? catatan,
  }) async {
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      final payload = <String, dynamic>{
        'guru_id': guruId,
        'nama_perangkat': namaPerangkat,
        'jenis': jenis,
        'status': status,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      };
      final newItem = await _repository.createPerangkat(token, payload);
      _detail?.perangkatList.insert(0, newItem);
      return true;
    } catch (e) {
      _saveError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updatePerangkat(
    String token,
    int id,
    String namaPerangkat,
    String jenis,
    String status, {
    String? catatan,
  }) async {
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      final payload = <String, dynamic>{
        'nama_perangkat': namaPerangkat,
        'jenis': jenis,
        'status': status,
        'catatan': catatan,
      };
      final updated = await _repository.updatePerangkat(token, id, payload);
      if (_detail != null) {
        final idx = _detail!.perangkatList.indexWhere((p) => p.id == id);
        if (idx != -1) {
          _detail!.perangkatList[idx] = updated;
        }
      }
      return true;
    } catch (e) {
      _saveError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deletePerangkat(String token, int id) async {
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      await _repository.deletePerangkat(token, id);
      _detail?.perangkatList.removeWhere((p) => p.id == id);
      return true;
    } catch (e) {
      _saveError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
