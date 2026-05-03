import '../../core/network/api_response.dart';
import '../models/absensi_guru_model.dart';

abstract class LearningRepository {
  // Teacher Attendance
  Future<PaginatedResponse<Map<String, dynamic>>> getTeacherAttendance({int page = 1, String? date});
  Future<void> submitTeacherAttendance(Map<String, dynamic> data);

  // Teaching Notes
  Future<PaginatedResponse<Map<String, dynamic>>> getTeachingNotes({int page = 1});
  Future<Map<String, dynamic>> createTeachingNote(Map<String, dynamic> data);

  // Teacher Evaluation
  Future<PaginatedResponse<Map<String, dynamic>>> getTeacherEvaluations({int page = 1});
  Future<Map<String, dynamic>> submitEvaluation(Map<String, dynamic> data);

  // Learning Devices
  Future<PaginatedResponse<Map<String, dynamic>>> getLearningDevices({int page = 1});
  Future<Map<String, dynamic>> uploadLearningDevice(Map<String, dynamic> data);

  // Reviews
  Future<PaginatedResponse<Map<String, dynamic>>> getPrincipalReviews({int page = 1});
  Future<PaginatedResponse<Map<String, dynamic>>> getVicePrincipalReviews({int page = 1});
  Future<Map<String, dynamic>> submitPrincipalReview(int id, Map<String, dynamic> data);
  Future<Map<String, dynamic>> submitVicePrincipalReview(int id, Map<String, dynamic> data);


  /// Photo wajib (base64 encoded)
  Future<AbsensiGuruModel> submitAbsensiGuru({
    required String namaGuru,
    required DateTime tanggal,
    required String status,
    required String fotoBase64,
    String? keterangan,
  });

  /// Get list absensi guru untuk history
  ///
  /// Backend endpoint: GET /api/learning/absensi-guru
  Future<List<AbsensiGuruModel>> getAbsensiGuruList({
    int page = 1,
    String? date,
  });
}
