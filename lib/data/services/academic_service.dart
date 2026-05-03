import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/user_search_model.dart';
import '../repositories/academic_repository.dart';

class AcademicService implements AcademicRepository {
  final DioClient _dioClient;

  AcademicService({required DioClient dioClient}) : _dioClient = dioClient;

  // ─── Classes ─────────────────────────────────────────────
  @override
  Future<PaginatedResponse<ClassModel>> getClasses({
    int page = 1,
    String? search,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.classes,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
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
        .map((item) => ClassModel.fromJson(item as Map<String, dynamic>))
        .where((kelas) {
      if (keyword == null || keyword.isEmpty) return true;

      return kelas.namaKelas.toLowerCase().contains(keyword) ||
          kelas.tingkat.toLowerCase().contains(keyword) ||
          (kelas.waliKelasNama ?? '').toLowerCase().contains(keyword);
    }).toList();

    return PaginatedResponse<ClassModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<ClassModel> getClassById(String id) async {
    final response = await _dioClient.get('${ApiEndpoints.classes}/$id');

    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return ClassModel.fromJson(raw['data'] as Map<String, dynamic>);
    }

    return ClassModel.fromJson(raw as Map<String, dynamic>);
  }

  @override
  Future<ClassModel> createClass(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiEndpoints.classes,
      data: data,
    );

    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return ClassModel.fromJson(raw['data'] as Map<String, dynamic>);
    }

    return ClassModel.fromJson(raw as Map<String, dynamic>);
  }

  @override
  Future<ClassModel> updateClass(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put(
      '${ApiEndpoints.classes}/$id',
      data: data,
    );

    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return ClassModel.fromJson(raw['data'] as Map<String, dynamic>);
    }

    return ClassModel.fromJson(raw as Map<String, dynamic>);
  }

  @override
  Future<void> deleteClass(String id) async {
    await _dioClient.delete('${ApiEndpoints.classes}/$id');
  }

  @override
  Future<List<UserSearchModel>> searchWaliKelas(String query) async {
    final keyword = query.trim();

    if (keyword.isEmpty) {
      return [];
    }

    final response = await _dioClient.get(
      ApiEndpoints.authUsersSearch,
      queryParameters: {
        'q': keyword,
        'role': 'wali-kelas',
      },
    );

    final raw = response.data;

    List<dynamic> rows = [];

    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) {
        rows = raw['data'] as List;
      } else if (raw['users'] is List) {
        rows = raw['users'] as List;
      }
    }

    return rows
        .map((item) => UserSearchModel.fromJson(item as Map<String, dynamic>))
        .where((user) => user.id.isNotEmpty)
        .toList();
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
    final response = await _dioClient.post(
      ApiEndpoints.students,
      data: data,
    );

    return StudentModel.fromJson(response.data['data']);
  }

  @override
  Future<StudentModel> updateStudent(
      String id,
      Map<String, dynamic> data,
      ) async {
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

  // ─── Announcements / Pengumuman ──────────────────────────
  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getAnnouncements({
    int page = 1,
  }) async {
    final response = await _dioClient.get(ApiEndpoints.announcements);

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

    final items = rows.map((item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList();

    return PaginatedResponse<Map<String, dynamic>>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
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

    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }

    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  @override
  Future<Map<String, dynamic>> updateAnnouncement(
      String id,
      Map<String, dynamic> data,
      ) async {
    final response = await _dioClient.put(
      '${ApiEndpoints.announcements}/$id',
      data: data,
    );

    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }

    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    await _dioClient.delete('${ApiEndpoints.announcements}/$id');
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
        if (classId != null) 'class_id': classId,
        if (teacherId != null) 'teacher_id': teacherId,
      },
    );

    final raw = response.data;

    if (raw is List) {
      return List<Map<String, dynamic>>.from(raw);
    }

    if (raw is Map<String, dynamic> && raw['data'] is List) {
      return List<Map<String, dynamic>>.from(raw['data']);
    }

    return [];
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
          (json) => json as Map<String, dynamic>,
    );
  }
}