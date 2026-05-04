import '../models/announcement_model.dart';

abstract class AnnouncementRepository {
  /// Get list pengumuman terbaru
  ///
  /// Backend endpoint: GET /api/academic/pengumuman
  ///
  /// [limit] — jumlah maksimal pengumuman yang di-return (default 5)
  Future<List<AnnouncementModel>> getAnnouncements({int limit = 5});

  /// Get detail pengumuman by ID
  ///
  /// Backend endpoint: GET /api/academic/pengumuman/:id
  ///
  /// Note: Kalau backend tidak punya endpoint detail terpisah,
  /// pakai data dari list yang sudah di-fetch.
  Future<AnnouncementModel> getAnnouncementById(int id);
}