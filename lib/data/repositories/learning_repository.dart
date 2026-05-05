import '../../core/network/api_response.dart';
import '../models/absensi_guru_model.dart';

abstract class LearningRepository {
  // =============================
  // ABSENSI GURU
  // =============================
  Future<List<AbsensiGuruModel>> getAbsensiGuruList({
    int page = 1,
    String? date,
  });

  Future<AbsensiGuruModel> submitAbsensiGuru({
    required String namaGuru,
    required DateTime tanggal,
    required String status,
    required String fotoBase64,
    String? keterangan,
  });

  // =============================
  // CATATAN MENGAJAR
  // =============================
  Future<PaginatedResponse<Map<String, dynamic>>> getTeachingNotes({int page = 1});
  Future<Map<String, dynamic>> createTeachingNote(Map<String, dynamic> data);

  // =============================
  // EVALUASI
  // =============================
  Future<PaginatedResponse<Map<String, dynamic>>> getTeacherEvaluations({int page = 1});
  Future<Map<String, dynamic>> submitEvaluation(Map<String, dynamic> data);

  // =============================
  // PERANGKAT
  // =============================
  Future<PaginatedResponse<Map<String, dynamic>>> getLearningDevices({int page = 1});
  Future<Map<String, dynamic>> uploadLearningDevice(Map<String, dynamic> data);

  // =============================
  // REVIEW
  // =============================
  Future<Map<String, dynamic>> submitPrincipalReview(int id, Map<String, dynamic> data);
  Future<Map<String, dynamic>> submitVicePrincipalReview(int id, Map<String, dynamic> data);
}