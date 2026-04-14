import '../../core/network/api_response.dart';

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
  Future<Map<String, dynamic>> submitPrincipalReview(Map<String, dynamic> data);
  Future<PaginatedResponse<Map<String, dynamic>>> getVicePrincipalReviews({int page = 1});
  Future<Map<String, dynamic>> submitVicePrincipalReview(Map<String, dynamic> data);
}
