import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../repositories/vocational_repository.dart';

class VocationalService implements VocationalRepository {
  final DioClient _dioClient;
  VocationalService({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutClasses({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.scoutGroups, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutAttendance({int page = 1, String? classId}) async {
    final r = await _dioClient.get(ApiEndpoints.scoutAttendance, queryParameters: {'page': page, if (classId != null) 'class_id': classId});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<void> submitScoutAttendance(Map<String, dynamic> data) async {
    await _dioClient.post(ApiEndpoints.scoutAttendance, data: data);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutReports({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.activityReport, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createScoutReport(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.activityReport, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getPklLocationReports({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.pklLocation, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> submitPklLocationReport(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.pklLocation, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getPklProgressReports({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.pklProgress, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> submitPklProgressReport(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.pklProgress, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }
}
