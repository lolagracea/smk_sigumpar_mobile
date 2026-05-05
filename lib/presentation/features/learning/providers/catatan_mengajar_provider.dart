import 'package:flutter/material.dart';
import '../../../../data/repositories/learning_repository.dart';

class CatatanMengajarProvider extends ChangeNotifier {
  final LearningRepository repository;

  CatatanMengajarProvider(this.repository);

  List<Map<String, dynamic>> data = [];
  bool isLoading = false;

  Future<void> load() async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await repository.getTeachingNotes();
      data = List<Map<String, dynamic>>.from(res.items ?? []);
    } catch (e) {
      debugPrint('Catatan error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}