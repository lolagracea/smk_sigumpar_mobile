import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../repositories/learning_repository.dart';
import '../models/absensi_guru_model.dart';

class LearningService implements LearningRepository {
  final DioClient _dioClient;
  LearningService({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getTeacherAttendance({int page = 1, String? date}) async {
    final r = await _dioClient.get(ApiEndpoints.teacherAttendance, queryParameters: {'page': page, if (date != null) 'date': date});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<void> submitTeacherAttendance(Map<String, dynamic> data) async {
    await _dioClient.post(ApiEndpoints.teacherAttendance, data: data);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getTeachingNotes({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.teachingNotes, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createTeachingNote(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.teachingNotes, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getTeacherEvaluations({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.teacherEvaluation, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> submitEvaluation(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.teacherEvaluation, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getLearningDevices({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.learningDevices, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> uploadLearningDevice(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.learningDevices, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getPrincipalReviews({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.learningDevices, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> submitPrincipalReview(int id, Map<String, dynamic> data) async {
    final r = await _dioClient.put(
      ApiEndpoints.learningDeviceReviewKepsek(id),
      data: data,
    );
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getVicePrincipalReviews({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.learningDevices, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> submitVicePrincipalReview(int id, Map<String, dynamic> data) async {
    final r = await _dioClient.put(
      ApiEndpoints.learningDeviceReviewWakasek(id),
      data: data,
    );
    return r.data['data'] as Map<String, dynamic>;
  }

  // ════════════════════════════════════════════════════════════════
  // === ABSENSI GURU (NEW METHODS) ===
  // ════════════════════════════════════════════════════════════════

  @override
  Future<AbsensiGuruModel> submitAbsensiGuru({
    required String namaGuru,
    required DateTime tanggal,
    required String status,
    required String fotoBase64,
    String? keterangan,
  }) async {
    // Format tanggal: YYYY-MM-DD
    final tanggalStr = tanggal.toIso8601String().split('T').first;

    // Get current time untuk jam_masuk: HH:mm:ss
    final now = DateTime.now();
    final jamMasuk =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final response = await _dioClient.post(
      ApiEndpoints.teacherAttendance,
      data: {
        'nama_guru': namaGuru,
        'mata_pelajaran': '-', // Backend default '-'
        'jam_masuk': jamMasuk,
        'tanggal': tanggalStr,
        'status': status,
        'foto': fotoBase64,
        if (keterangan != null && keterangan.isNotEmpty)
          'keterangan': keterangan,
      },
    );

    final data = response.data['data'] ?? response.data;
    return AbsensiGuruModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<AbsensiGuruModel>> getAbsensiGuruList({
    int page = 1,
    String? date,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.teacherAttendance,
      queryParameters: {
        'page': page,
        if (date != null) 'date': date,
      },
    );

    final responseData = response.data;

    // Handle berbagai format response backend
    List<dynamic> rawList;
    if (responseData is List) {
      rawList = responseData;
    } else if (responseData is Map) {
      rawList = (responseData['data'] ?? responseData['items'] ?? []) as List;
    } else {
      rawList = [];
    }

    return rawList
        .map((e) => AbsensiGuruModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
