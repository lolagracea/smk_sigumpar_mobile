import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../models/absensi_guru_model.dart';
import '../repositories/learning_repository.dart';

class LearningService implements LearningRepository {
  final DioClient _dio;

  LearningService({required DioClient dioClient}) : _dio = dioClient;

  // =====================================================
  // ABSENSI
  // =====================================================

  @override
  Future<List<AbsensiGuruModel>> getAbsensiGuruList({
    int page = 1,
    String? date,
  }) async {
    final res = await _dio.get(
      '/api/learning/absensi-guru',
      queryParameters: {
        if (date != null) 'tanggal': date,
      },
    );

    final list = res.data['data'] as List;

    return list.map((e) => AbsensiGuruModel.fromJson(e)).toList();
  }

  @override
  Future<AbsensiGuruModel> submitAbsensiGuru({
    required String namaGuru,
    required DateTime tanggal,
    required String status,
    required String fotoBase64,
    String? keterangan,
  }) async {
    final res = await _dio.post(
      '/api/learning/absensi-guru',
      data: {
        'nama_guru': namaGuru,
        'tanggal': tanggal.toIso8601String().split('T').first,
        'status': status,
        'foto': fotoBase64,
        if (keterangan != null) 'keterangan': keterangan,
      },
    );

    return AbsensiGuruModel.fromJson(res.data['data']);
  }

  // =====================================================
  // CATATAN
  // =====================================================

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getTeachingNotes({int page = 1}) async {
    final res = await _dio.get('/api/learning/catatan-mengajar');

    return PaginatedResponse.fromJson(
      {
        "data": res.data['data'],
        "total": res.data['data'].length,
        "page": 1
      },
          (j) => j as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, dynamic>> createTeachingNote(Map<String, dynamic> data) async {
    final res = await _dio.post('/api/learning/catatan-mengajar', data: data);
    return res.data['data'];
  }

  // =====================================================
  // EVALUASI
  // =====================================================

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getTeacherEvaluations({int page = 1}) async {
    final res = await _dio.get('/api/learning/evaluasi-guru');

    return PaginatedResponse.fromJson(
      {
        "data": res.data['data'],
        "total": res.data['data'].length,
        "page": 1
      },
          (j) => j as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, dynamic>> submitEvaluation(Map<String, dynamic> data) async {
    final res = await _dio.post('/api/learning/evaluasi-guru', data: data);
    return res.data['data'];
  }

  // =====================================================
  // PERANGKAT
  // =====================================================

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getLearningDevices({int page = 1}) async {
    final res = await _dio.get('/api/learning/perangkat');

    return PaginatedResponse.fromJson(
      {
        "data": res.data['data'],
        "total": res.data['data'].length,
        "page": 1
      },
          (j) => j as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, dynamic>> uploadLearningDevice(Map<String, dynamic> data) async {
    final res = await _dio.post('/api/learning/perangkat', data: data);
    return res.data['data'];
  }

  // =====================================================
  // REVIEW
  // =====================================================

  @override
  Future<Map<String, dynamic>> submitPrincipalReview(int id, Map<String, dynamic> data) async {
    final res = await _dio.put(
      '/api/learning/perangkat/$id/review-kepsek',
      data: data,
    );
    return res.data['data'];
  }

  @override
  Future<Map<String, dynamic>> submitVicePrincipalReview(int id, Map<String, dynamic> data) async {
    final res = await _dio.put(
      '/api/learning/perangkat/$id/review-wakasek',
      data: data,
    );
    return res.data['data'];
  }
}