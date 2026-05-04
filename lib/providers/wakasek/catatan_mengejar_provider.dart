import 'package:flutter/material.dart';

import '../../data/models/wakasek_models.dart';
import '../../data/repositories/wakasek_repository.dart';

class CatatanMengajarProvider extends ChangeNotifier {
  CatatanMengajarProvider(this._repository);

  final WakasekRepository _repository;

  List<CatatanMengajarModel> _items = <CatatanMengajarModel>[];
  bool _isLoading = false;
  String? _errorMessage;
  String? _filterGuruId;
  String? _filterTanggal;

  List<CatatanMengajarModel> get items =>
      List<CatatanMengajarModel>.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get filterGuruId => _filterGuruId;
  String? get filterTanggal => _filterTanggal;

  Future<void> load({required String token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repository.getCatatanMengajar(
        guruId: _filterGuruId,
        tanggal: _filterTanggal,
        token: token,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter({String? guruId, String? tanggal}) {
    _filterGuruId = guruId;
    _filterTanggal = tanggal;
    notifyListeners();
  }

  void resetFilter() {
    _filterGuruId = null;
    _filterTanggal = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
