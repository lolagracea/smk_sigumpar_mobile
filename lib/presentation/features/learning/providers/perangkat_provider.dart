import 'package:flutter/material.dart';
import '../../../../data/repositories/learning_repository.dart';

class PerangkatProvider extends ChangeNotifier {
  final LearningRepository repository;

  PerangkatProvider(this.repository);

  List<Map<String, dynamic>> data = [];
  bool isLoading = false;

  Future<void> load() async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await repository.getLearningDevices();
      data = List<Map<String, dynamic>>.from(res.items ?? []);
    } catch (e) {
      debugPrint('Perangkat error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> review(int id, String status) async {
    await repository.submitVicePrincipalReview(
      id,
      {'status': status},
    );
    await load();
  }
}