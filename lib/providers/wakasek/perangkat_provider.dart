import 'package:flutter/material.dart';

import '../../data/models/wakasek_models.dart';
import '../../data/repositories/wakasek_repository.dart';

class PerangkatProvider extends ChangeNotifier {
  PerangkatProvider(this._repository);

  final WakasekRepository _repository;

  // State utama
  List<PerangkatModel> _items = <PerangkatModel>[];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter
  String? _filterStatus;
  String? _filterJenis;
  String _search = '';

  // State review
  bool _isReviewing = false;
  List<RiwayatReviewModel> _riwayat = <RiwayatReviewModel>[];
  bool _isLoadingRiwayat = false;

  // ─── Getters ──────────────────────────────────────────────
  List<PerangkatModel> get items => List<PerangkatModel>.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isReviewing => _isReviewing;
  List<RiwayatReviewModel> get riwayat =>
      List<RiwayatReviewModel>.unmodifiable(_riwayat);
  bool get isLoadingRiwayat => _isLoadingRiwayat;
  String? get filterStatus => _filterStatus;
  String? get filterJenis => _filterJenis;

  // ─── Load list ────────────────────────────────────────────
  Future<void> load({required String token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repository.getPerangkat(
        statusReview: _filterStatus,
        jenisDokumen: _filterJenis,
        search: _search.isEmpty ? null : _search,
        token: token,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter({String? status, String? jenis, String? search}) {
    _filterStatus = status;
    _filterJenis = jenis;
    if (search != null) _search = search;
    notifyListeners();
  }

  void resetFilter() {
    _filterStatus = null;
    _filterJenis = null;
    _search = '';
    notifyListeners();
  }

  // ─── Review ───────────────────────────────────────────────
  Future<bool> review({
    required int id,
    required String status,
    String? catatan,
    required String token,
  }) async {
    _isReviewing = true;
    notifyListeners();

    try {
      await _repository.reviewPerangkat(
        id: id,
        status: status,
        catatan: catatan,
        token: token,
      );
      // Update item lokal langsung tanpa reload full
      final idx = _items.indexWhere((p) => p.id == id);
      if (idx != -1) {
        final old = _items[idx];
        _items[idx] = PerangkatModel(
          id: old.id,
          guruId: old.guruId,
          namaGuru: old.namaGuru,
          namaDokumen: old.namaDokumen,
          jenisDokumen: old.jenisDokumen,
          fileName: old.fileName,
          fileMime: old.fileMime,
          statusReview: status,
          catatanReview: catatan,
          reviewedBy: 'Anda',
          reviewedAt: DateTime.now().toIso8601String(),
          versi: old.versi,
          tanggalUpload: old.tanggalUpload,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isReviewing = false;
      notifyListeners();
    }
  }

  // ─── Riwayat Review ──────────────────────────────────────
  Future<void> loadRiwayat({required int id, required String token}) async {
    _isLoadingRiwayat = true;
    _riwayat = [];
    notifyListeners();

    try {
      _riwayat = await _repository.getRiwayatReview(id: id, token: token);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingRiwayat = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
