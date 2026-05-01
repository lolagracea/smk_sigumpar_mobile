import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../repositories/academic_repository.dart';

class AcademicService implements AcademicRepository {
  final DioClient _dioClient;

  AcademicService({required DioClient dioClient}) : _dioClient = dioClient;

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) return responseData;

    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];

      if (data is List) return data;

      if (data is Map<String, dynamic>) {
        if (data['data'] is List) return data['data'] as List;
        if (data['items'] is List) return data['items'] as List;
      }
    }

    return [];
  }

  Map<String, dynamic> _extractObject(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];

      if (data is Map<String, dynamic>) return data;

      return responseData;
    }

    return {};
  }

  // ─── Classes ─────────────────────────────────────────────

  @override
  Future<List<ClassModel>> getClasses({String? search}) async {
    final response = await _dioClient.get(
      ApiEndpoints.classes,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final list = _extractList(response.data);

    return list
        .map((item) => ClassModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClassModel> getClassById(String id) async {
    final response = await _dioClient.get('${ApiEndpoints.classes}/$id');
    return ClassModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<ClassModel> createClass(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiEndpoints.classes,
      data: data,
    );

    return ClassModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<ClassModel> updateClass(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put(
      '${ApiEndpoints.classes}/$id',
      data: data,
    );

    return ClassModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<void> deleteClass(String id) async {
    await _dioClient.delete('${ApiEndpoints.classes}/$id');
  }

  // ─── Students ─────────────────────────────────────────────

  @override
  Future<PaginatedResponse<StudentModel>> getStudents({
    int page = 1,
    String? classId,
    String? search,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.students,
      queryParameters: {
        'page': page,
        if (classId != null) 'kelas_id': classId,
        if (search != null) 'search': search,
      },
    );

    return PaginatedResponse.fromJson(
      response.data,
          (json) => StudentModel.fromJson(json),
    );
  }

  @override
  Future<StudentModel> getStudentById(String id) async {
    final response = await _dioClient.get('${ApiEndpoints.students}/$id');
    return StudentModel.fromJson(response.data['data']);
  }

  @override
  Future<StudentModel> createStudent(Map<String, dynamic> data) async {
    final response = await _dioClient.post(ApiEndpoints.students, data: data);
    return StudentModel.fromJson(response.data['data']);
  }

  @override
  Future<StudentModel> updateStudent(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put(
      '${ApiEndpoints.students}/$id',
      data: data,
    );

    return StudentModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteStudent(String id) async {
    await _dioClient.delete('${ApiEndpoints.students}/$id');
  }

  // ─── Teachers ─────────────────────────────────────────────

  @override
  Future<PaginatedResponse<TeacherModel>> getTeachers({
    int page = 1,
    String? search,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.teachers,
      queryParameters: {
        'page': page,
        if (search != null) 'search': search,
      },
    );

    return PaginatedResponse.fromJson(
      response.data,
          (json) => TeacherModel.fromJson(json),
    );
  }

  @override
  Future<TeacherModel> getTeacherById(String id) async {
    final response = await _dioClient.get('${ApiEndpoints.teachers}/$id');
    return TeacherModel.fromJson(response.data['data']);
  }

  // ─── Announcements ────────────────────────────────────────

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getAnnouncements({
    int page = 1,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.announcements,
      queryParameters: {'page': page},
    );

    return PaginatedResponse.fromJson(
      response.data,
          (json) => json,
    );
  }

  @override
  Future<Map<String, dynamic>> createAnnouncement(
      Map<String, dynamic> data,
      ) async {
    final response = await _dioClient.post(
      ApiEndpoints.announcements,
      data: data,
    );

    return response.data['data'] as Map<String, dynamic>;
  }

  // ─── Schedules ────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getSchedules({
    String? classId,
    String? teacherId,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.schedules,
      queryParameters: {
        if (classId != null) 'kelas_id': classId,
        if (teacherId != null) 'guru_id': teacherId,
      },
    );

    final list = _extractList(response.data);

    return list.map((item) => item as Map<String, dynamic>).toList();
  }

  // ─── Letters ──────────────────────────────────────────────

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getLetters({
    int page = 1,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.letters,
      queryParameters: {'page': page},
    );

    return PaginatedResponse.fromJson(
      response.data,
          (json) => json,
    );
  }
}