import 'package:flutter/material.dart';
import '../../../../data/repositories/learning_repository.dart';

class EvaluasiGuruProvider extends ChangeNotifier {
  final LearningRepository repository;

  EvaluasiGuruProvider(this.repository);

  List<Map<String, dynamic>> data = [];
  bool isLoading = false;

  Future<void> load() async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await repository.getTeacherEvaluations();
      data = List<Map<String, dynamic>>.from(res.items ?? []);
    } catch (e) {
      debugPrint('Evaluasi error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submit(Map<String, dynamic> body) async {
    await repository.submitEvaluation(body);
    await load();
  }
}