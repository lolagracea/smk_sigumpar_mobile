import 'package:flutter/material.dart';

import '../../data/models/arsip_surat_model.dart';
import '../../data/repositories/academic_repository.dart';

class ArsipSuratProvider extends ChangeNotifier {
  ArsipSuratProvider(this._repository);

  final AcademicRepository _repository;
  final List<ArsipSuratModel> _items = <ArsipSuratModel>[];
  bool _isLoading = false;

  List<ArsipSuratModel> get items => List<ArsipSuratModel>.unmodifiable(_items);
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final List<ArsipSuratModel> result = await _repository.getArsipSurat();
    _items
      ..clear()
      ..addAll(result);
    _isLoading = false;
    notifyListeners();
  }
}
