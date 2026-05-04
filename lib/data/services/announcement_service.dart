import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../repositories/announcement_repository.dart';

class AnnouncementService implements AnnouncementRepository {
  final DioClient _dioClient;

  AnnouncementService({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getAnnouncements(
      {int page = 1}) async {
    final response = await _dioClient.get(
      ApiEndpoints.announcements,
      queryParameters: {'page': page},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, dynamic>> getAnnouncementById(String id) async {
    final response = await _dioClient.get('${ApiEndpoints.announcements}/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createAnnouncement(
      Map<String, dynamic> data) async {
    final response =
        await _dioClient.post(ApiEndpoints.announcements, data: data);
    return response.data['data'] as Map<String, dynamic>;
  }
}
