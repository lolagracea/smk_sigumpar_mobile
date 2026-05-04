import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/user_search_model.dart';
import '../repositories/academic_repository.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../models/mapel_assignment_model.dart';
import '../models/schedule_model.dart';
import '../models/arsip_surat_model.dart';

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
        .map((item) => StudentModel.fromJson(
      Map<String, dynamic>.from(item as Map),
    ))
        .where((siswa) {
      if (keyword == null || keyword.isEmpty) return true;

      return siswa.nisn.toLowerCase().contains(keyword) ||
          siswa.namaLengkap.toLowerCase().contains(keyword) ||
          siswa.namaKelas.toLowerCase().contains(keyword);
    }).toList();

    return PaginatedResponse<StudentModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<StudentModel> getStudentById(String id) async {
    final response = await _dioClient.get('${ApiEndpoints.students}/$id');
    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return StudentModel.fromJson(raw['data'] as Map<String, dynamic>);
    }

    return StudentModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<StudentModel> createStudent(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiEndpoints.students,
      data: data,
    );

    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return StudentModel.fromJson(raw['data'] as Map<String, dynamic>);
    }

    return StudentModel.fromJson(Map<String, dynamic>.from(raw as Map));
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

    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return StudentModel.fromJson(raw['data'] as Map<String, dynamic>);
    }

    return StudentModel.fromJson(Map<String, dynamic>.from(raw as Map));
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

  // ─── Schedules / Jadwal Mengajar ─────────────────────────
  @override
  Future<List<ScheduleModel>> getSchedules({
    String? classId,
    String? teacherId,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.schedules,
      queryParameters: {
        if (classId != null && classId.isNotEmpty) 'kelas_id': classId,
        if (teacherId != null && teacherId.isNotEmpty) 'guru_id': teacherId,
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

    return rows
        .map(
          (item) => ScheduleModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }

  @override
  Future<ScheduleModel> createSchedule(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiEndpoints.schedules,
      data: data,
    );

    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return ScheduleModel.fromJson(raw['data'] as Map<String, dynamic>);
    }

    return ScheduleModel.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  @override
  Future<ScheduleModel> updateSchedule(
      String id,
      Map<String, dynamic> data,
      ) async {
    final response = await _dioClient.put(
      '${ApiEndpoints.schedules}/$id',
      data: data,
    );

    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return ScheduleModel.fromJson(raw['data'] as Map<String, dynamic>);
    }

    return ScheduleModel.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  @override
  Future<void> deleteSchedule(String id) async {
    await _dioClient.delete('${ApiEndpoints.schedules}/$id');
  }

  @override
  Future<List<UserSearchModel>> searchGuruMapel(String query) async {
    final keyword = query.trim();

    if (keyword.isEmpty) {
      return [];
    }

    final response = await _dioClient.get(
      ApiEndpoints.authUsersSearch,
      queryParameters: {
        'q': keyword,
        'role': 'guru-mapel',
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
        .map(
          (item) => UserSearchModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .where((user) => user.id.isNotEmpty)
        .toList();
  }

  @override
  Future<List<MapelAssignmentModel>> getMapelByGuru(String guruId) async {
    if (guruId.trim().isEmpty) {
      return [];
    }

    final response = await _dioClient.get(
      ApiEndpoints.getSubjectsByGuruId(guruId),
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

    return rows
        .map(
          (item) => MapelAssignmentModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .where((item) => item.mapelId.isNotEmpty && item.kelasId.isNotEmpty)
        .toList();
  }

  // ─── Letters / Arsip Surat ──────────────────────────────
  @override
  Future<PaginatedResponse<ArsipSuratModel>> getLetters({
    int page = 1,
  }) async {
    final response = await _dioClient.get(ApiEndpoints.letters);

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
        .map(
          (item) => ArsipSuratModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();

    return PaginatedResponse<ArsipSuratModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<ArsipSuratModel> createLetter({
    required String nomorSurat,
    required PlatformFile file,
  }) async {
    final formData = await _buildLetterFormData(
      nomorSurat: nomorSurat,
      file: file,
    );

    final response = await _dioClient.post(
      ApiEndpoints.letters,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return ArsipSuratModel.fromJson(raw['data'] as Map<String, dynamic>);
    }

    return ArsipSuratModel.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  @override
  Future<ArsipSuratModel> updateLetter({
    required String id,
    required String nomorSurat,
    PlatformFile? file,
  }) async {
    final formData = await _buildLetterFormData(
      nomorSurat: nomorSurat,
      file: file,
    );

    final response = await _dioClient.put(
      '${ApiEndpoints.letters}/$id',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    final raw = response.data;

    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return ArsipSuratModel.fromJson(raw['data'] as Map<String, dynamic>);
    }

    return ArsipSuratModel.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  @override
  Future<void> deleteLetter(String id) async {
    await _dioClient.delete('${ApiEndpoints.letters}/$id');
  }

  Future<FormData> _buildLetterFormData({
    required String nomorSurat,
    PlatformFile? file,
  }) async {
    final formData = FormData.fromMap({
      'nomor_surat': nomorSurat,
    });

    if (file != null) {
      MultipartFile multipartFile;

      if (file.bytes != null) {
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        );
      } else if (file.path != null) {
        multipartFile = await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        );
      } else {
        throw Exception('File tidak valid atau tidak bisa dibaca.');
      }

      formData.files.add(
        MapEntry(
          'file',
          multipartFile,
        ),
      );
    }

    return formData;
  }
}