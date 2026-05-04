import 'package:flutter/foundation.dart';

import '../../../../data/models/announcement_model.dart';
import '../../../../data/repositories/announcement_repository.dart';

enum AnnouncementStatus { idle, loading, loaded, error }

class AnnouncementProvider extends ChangeNotifier {
  final AnnouncementRepository _repository;

  AnnouncementProvider({required AnnouncementRepository repository})
      : _repository = repository;

  // ════════════════════════════════════════════════════════
  // === STATE ===
  // ════════════════════════════════════════════════════════

  AnnouncementStatus _status = AnnouncementStatus.idle;
  List<AnnouncementModel> _announcements = [];
  AnnouncementModel? _selectedAnnouncement;
  String? _errorMessage;

  // ════════════════════════════════════════════════════════
  // === GETTERS ===
  // ════════════════════════════════════════════════════════

  AnnouncementStatus get status => _status;
  List<AnnouncementModel> get announcements => _announcements;
  AnnouncementModel? get selectedAnnouncement => _selectedAnnouncement;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AnnouncementStatus.loading;
  bool get hasError => _status == AnnouncementStatus.error;
  bool get hasData => _announcements.isNotEmpty;
  bool get isEmpty => _status == AnnouncementStatus.loaded && _announcements.isEmpty;

  // ════════════════════════════════════════════════════════
  // === FETCH ANNOUNCEMENTS ===
  // ════════════════════════════════════════════════════════

  Future<void> loadAnnouncements({int limit = 5}) async {
    _status = AnnouncementStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getAnnouncements(limit: limit);
      _announcements = result;
      _status = AnnouncementStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = AnnouncementStatus.error;
      _errorMessage = _parseError(e);
      notifyListeners();
      if (kDebugMode) print('❌ Load announcements error: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // === GET DETAIL ===
  // ════════════════════════════════════════════════════════

  /// Set selected announcement (untuk detail screen)
  /// Kalau sudah ada di list, pakai dari list (no API call)
  /// Kalau belum, fetch dari backend
  Future<void> selectAnnouncement(int id) async {
    // Coba ambil dari cache (list) dulu
    final cached = _announcements.where((a) => a.id == id).toList();
    if (cached.isNotEmpty) {
      _selectedAnnouncement = cached.first;
      notifyListeners();
      return;
    }

    // Kalau tidak ada di cache, fetch dari API
    _status = AnnouncementStatus.loading;
    notifyListeners();

    try {
      final detail = await _repository.getAnnouncementById(id);
      _selectedAnnouncement = detail;
      _status = AnnouncementStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = AnnouncementStatus.error;
      _errorMessage = _parseError(e);
      notifyListeners();
    }
  }

  /// Set selected announcement langsung dari object (no API call)
  void setSelectedAnnouncement(AnnouncementModel announcement) {
    _selectedAnnouncement = announcement;
    notifyListeners();
  }

  void clearSelected() {
    _selectedAnnouncement = null;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  // === HELPERS ===
  // ════════════════════════════════════════════════════════

  String _parseError(Object error) {
    final errorStr = error.toString();

    if (errorStr.contains('SocketException') ||
        errorStr.contains('Network')) {
      return 'Tidak ada koneksi internet';
    }

    if (errorStr.contains('TimeoutException')) {
      return 'Server tidak merespon';
    }

    if (errorStr.contains('404')) {
      return 'Pengumuman tidak ditemukan';
    }

    return errorStr
        .replaceAll('Exception: ', '')
        .replaceAll('NetworkExceptions: ', '')
        .replaceAll('DioException: ', '');
  }

  /// Refresh data (untuk pull-to-refresh)
  Future<void> refresh({int limit = 5}) async {
    await loadAnnouncements(limit: limit);
  }
}