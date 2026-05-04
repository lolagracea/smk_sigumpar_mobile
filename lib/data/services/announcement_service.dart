import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/announcement_model.dart';
import '../repositories/announcement_repository.dart';

class AnnouncementService implements AnnouncementRepository {
  final DioClient _dioClient;

  AnnouncementService({required DioClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<List<AnnouncementModel>> getAnnouncements({int limit = 5}) async {
    final response = await _dioClient.get(
      ApiEndpoints.announcements,
      queryParameters: {'limit': limit},
    );

    final responseData = response.data;

    // Handle berbagai format response backend
    List<dynamic> rawList;
    if (responseData is List) {
      rawList = responseData;
    } else if (responseData is Map) {
      rawList = (responseData['data'] ??
          responseData['items'] ??
          responseData['pengumuman'] ??
          []) as List;
    } else {
      rawList = [];
    }

    final announcements = rawList
        .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Sort by created_at descending (terbaru dulu)
    announcements.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(0);
      final bTime = b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

    // Apply limit
    if (announcements.length > limit) {
      return announcements.sublist(0, limit);
    }
    return announcements;
  }

  @override
  Future<AnnouncementModel> getAnnouncementById(int id) async {
    try {
      // Coba endpoint detail dulu (kalau ada)
      final response = await _dioClient.get(
        '${ApiEndpoints.announcements}/$id',
      );
      final data = response.data['data'] ?? response.data;
      return AnnouncementModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      // Kalau endpoint detail tidak ada, fetch list lalu cari by id
      final list = await getAnnouncements(limit: 100);
      return list.firstWhere(
            (a) => a.id == id,
        orElse: () => throw Exception('Pengumuman tidak ditemukan'),
      );
    }
  }
}