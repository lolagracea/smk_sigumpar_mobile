import 'package:flutter/material.dart';

import '../../data/models/siswa_model.dart';
import '../../data/repositories/academic_repository.dart';

class SiswaProvider extends ChangeNotifier {
  SiswaProvider(this._repository);

  final AcademicRepository _repository;
  final List<SiswaModel> _items = <SiswaModel>[];
  bool _isLoading = false;

  List<SiswaModel> get items => List<SiswaModel>.unmodifiable(_items);
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final List<SiswaModel> result = await _repository.getSiswa();
    _items
      ..clear()
      ..addAll(result);
    _isLoading = false;
    notifyListeners();
  }
}
