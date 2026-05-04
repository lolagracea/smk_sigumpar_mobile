import 'package:flutter/material.dart';

import '../../data/models/kelas_model.dart';
import '../../data/repositories/academic_repository.dart';

class KelasProvider extends ChangeNotifier {
  KelasProvider(this._repository);

  final AcademicRepository _repository;
  final List<KelasModel> _items = <KelasModel>[];
  bool _isLoading = false;

  List<KelasModel> get items => List<KelasModel>.unmodifiable(_items);
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final List<KelasModel> result = await _repository.getKelas();
    _items
      ..clear()
      ..addAll(result);
    _isLoading = false;
    notifyListeners();
  }
}
