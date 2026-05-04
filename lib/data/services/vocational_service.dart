import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../repositories/vocational_repository.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/pkl_location_model.dart';
import '../models/pkl_progress_model.dart';

class VocationalService implements VocationalRepository {
  final DioClient _dioClient;
  VocationalService({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutClasses({
    int page = 1,
  }) async {
    final r = await _dioClient.get(
      ApiEndpoints.scoutGroups,
      queryParameters: {'page': page},
    );
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutAttendance({
    int page = 1,
    String? classId,
  }) async {
    final r = await _dioClient.get(
      ApiEndpoints.scoutAttendance,
      queryParameters: {'page': page, if (classId != null) 'class_id': classId},
    );
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<void> submitScoutAttendance(Map<String, dynamic> data) async {
    await _dioClient.post(ApiEndpoints.scoutAttendance, data: data);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutReports({
    int page = 1,
  }) async {
    final r = await _dioClient.get(
      ApiEndpoints.activityReport,
      queryParameters: {'page': page},
    );
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createScoutReport(
    Map<String, dynamic> data,
  ) async {
    final r = await _dioClient.post(ApiEndpoints.activityReport, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<ClassModel>> getPklClasses({
    int page = 1,
    String? search,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.vocationalClasses,
      queryParameters: {
        'page': page,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final raw = response.data;
    List<dynamic> rows = [];

    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) {
        rows = raw['data'] as List;
      } else if (raw['data'] is Map<String, dynamic> &&
          raw['data']['data'] is List) {
        rows = raw['data']['data'] as List;
      }
    }

    final items = rows
        .map((item) => ClassModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<ClassModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<PaginatedResponse<StudentModel>> getPklStudents({
    int page = 1,
    String? classId,
    String? search,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.vocationalStudents,
      queryParameters: {
        'page': page,
        if (classId != null && classId.isNotEmpty) 'kelas_id': classId,
      },
    );

    final raw = response.data;
    List<dynamic> rows = [];

    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) {
        rows = raw['data'] as List;
      } else if (raw['data'] is Map<String, dynamic> &&
          raw['data']['data'] is List) {
        rows = raw['data']['data'] as List;
      }
    }

    final keyword = search?.trim().toLowerCase();

    final items = rows
        .map(
          (item) =>
              StudentModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .where((siswa) {
          if (keyword == null || keyword.isEmpty) return true;
          return siswa.nisn.toLowerCase().contains(keyword) ||
              siswa.namaLengkap.toLowerCase().contains(keyword) ||
              siswa.namaKelas.toLowerCase().contains(keyword);
        })
        .toList();

    return PaginatedResponse<StudentModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<PaginatedResponse<PklLocationModel>> getPklLocationReports({
    int page = 1,
    String? classId,
    String? studentId,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.pklLocation,
      queryParameters: {
        'page': page,
        if (classId != null && classId.isNotEmpty) 'kelas_id': classId,
        if (studentId != null && studentId.isNotEmpty) 'siswa_id': studentId,
      },
    );

    final raw = response.data;
    List<dynamic> rows = [];

    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) {
        rows = raw['data'] as List;
      } else if (raw['data'] is Map<String, dynamic> &&
          raw['data']['data'] is List) {
        rows = raw['data']['data'] as List;
      }
    }

    final items = rows
        .map((item) => PklLocationModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<PklLocationModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<PklLocationModel> submitPklLocationReport(
    Map<String, dynamic> data,
  ) async {
    final r = await _dioClient.post(ApiEndpoints.pklLocation, data: data);
    final raw = r.data;
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return PklLocationModel.fromJson(raw['data'] as Map<String, dynamic>);
    }
    return PklLocationModel.fromJson(raw as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResponse<PklProgressModel>> getPklProgressReports({
    int page = 1,
    String? classId,
    String? studentId,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.pklProgress,
      queryParameters: {
        'page': page,
        if (classId != null && classId.isNotEmpty) 'kelas_id': classId,
        if (studentId != null && studentId.isNotEmpty) 'siswa_id': studentId,
      },
    );

    final raw = response.data;
    List<dynamic> rows = [];

    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) {
        rows = raw['data'] as List;
      } else if (raw['data'] is Map<String, dynamic> &&
          raw['data']['data'] is List) {
        rows = raw['data']['data'] as List;
      }
    }

    final items = rows
        .map((item) => PklProgressModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<PklProgressModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<PklProgressModel> submitPklProgressReport(
    Map<String, dynamic> data,
  ) async {
    final r = await _dioClient.post(ApiEndpoints.pklProgress, data: data);
    final raw = r.data;
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return PklProgressModel.fromJson(raw['data'] as Map<String, dynamic>);
    }
    return PklProgressModel.fromJson(raw as Map<String, dynamic>);
  }
}
