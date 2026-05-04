import 'package:flutter/material.dart';
import '../../../../data/repositories/academic_repository.dart';

enum AnnouncementLoadState { initial, loading, loaded, error }

class AnnouncementProvider extends ChangeNotifier {
  final AcademicRepository _repository;

  AnnouncementProvider({required AcademicRepository repository})
      : _repository = repository;

  AnnouncementLoadState _state = AnnouncementLoadState.initial;
  List<Map<String, dynamic>> _announcements = [];
  int _page = 1;
  bool _hasMore = true;
  String? _error;

  AnnouncementLoadState get state => _state;
  List<Map<String, dynamic>> get announcements => _announcements;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> fetchAnnouncements({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _announcements = [];
      _hasMore = true;
    }
    if (!_hasMore) return;

    _state = AnnouncementLoadState.loading;
    notifyListeners();

    try {
      final result = await _repository.getAnnouncements(page: _page);
      _announcements.addAll(result.items);
      _hasMore = result.hasNextPage;
      _page++;
      _state = AnnouncementLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = AnnouncementLoadState.error;
    }
    notifyListeners();
  }
}
