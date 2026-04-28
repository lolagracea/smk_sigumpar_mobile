import 'package:flutter/material.dart';
import '../../../../data/repositories/asset_repository.dart';

enum AssetLoadState { initial, loading, loaded, error }

class AssetProvider extends ChangeNotifier {
  final AssetRepository _repository;

  AssetProvider({required AssetRepository repository})
      : _repository = repository;

  AssetLoadState _state = AssetLoadState.initial;
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _loans = [];
  String? _error;

  AssetLoadState get state => _state;
  List<Map<String, dynamic>> get submissions => _submissions;
  List<Map<String, dynamic>> get loans => _loans;
  String? get error => _error;

  Future<void> fetchSubmissions({bool refresh = false}) async {
    if (refresh) _submissions = [];
    _state = AssetLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getSubmissions();
      _submissions = result.items;
      _state = AssetLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = AssetLoadState.error;
    }
    notifyListeners();
  }

  Future<void> fetchLoans({bool refresh = false, String? status}) async {
    if (refresh) _loans = [];
    _state = AssetLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getItemLoans(status: status);
      _loans = result.items;
      _state = AssetLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = AssetLoadState.error;
    }
    notifyListeners();
  }
}
