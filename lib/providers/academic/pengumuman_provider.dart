import 'package:flutter/material.dart';

import '../../data/models/pengumuman_model.dart';
import '../../data/repositories/academic_repository.dart';

class PengumumanProvider extends ChangeNotifier {
  PengumumanProvider(this._repository);

  final AcademicRepository _repository;
  final List<PengumumanModel> _items = <PengumumanModel>[];
  bool _isLoading = false;

  List<PengumumanModel> get items => List<PengumumanModel>.unmodifiable(_items);
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final List<PengumumanModel> result = await _repository.getPengumuman();
    _items
      ..clear()
      ..addAll(result);
    _isLoading = false;
    notifyListeners();
  }
}
