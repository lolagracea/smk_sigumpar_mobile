import '../../../core/network/api_response.dart';

abstract class AnnouncementRepository {
  Future<PaginatedResponse<Map<String, dynamic>>> getAnnouncements(
      {int page = 1});
  Future<Map<String, dynamic>> getAnnouncementById(String id);
  Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> data);
}
