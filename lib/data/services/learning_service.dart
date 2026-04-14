import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../repositories/learning_repository.dart';

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
    final r = await _dioClient.get(ApiEndpoints.learningDevice, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> uploadLearningDevice(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.learningDevice, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getPrincipalReviews({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.principalReview, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> submitPrincipalReview(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.principalReview, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getVicePrincipalReviews({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.vicePrincipalReview, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> submitVicePrincipalReview(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.vicePrincipalReview, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }
}
