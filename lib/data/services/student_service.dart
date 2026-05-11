import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/attendance_model.dart';
import '../models/attendance_summary_model.dart';
import '../models/grade_model.dart';
import '../models/parenting_note_model.dart';
import '../models/cleanliness_model.dart';
import '../models/reflection_model.dart';
import '../models/summons_letter_model.dart';
import '../models/student_model.dart';
import '../repositories/student_repository.dart';

class StudentService implements StudentRepository {
  final DioClient _dioClient;
  StudentService({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<List<StudentModel>> getAllStudents() async {
    final response = await _dioClient.get(ApiEndpoints.students);
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => StudentModel.fromJson(json)).toList();
  }

  // ─── ABSENSI / KEHADIRAN ──────────────────────────────────────────
  @override
  Future<PaginatedResponse<AttendanceModel>> getAttendanceRecap({
    required String classId,
    String? date,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.attendanceRecap,
      queryParameters: {
        'kelas_id': classId,
        if (date != null) 'tanggal': date,
      },
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return PaginatedResponse(
      items: data.map((json) => AttendanceModel.fromJson(json)).toList(),
      currentPage: 1,
      lastPage: 1,
      total: data.length,
      perPage: data.length,
    );
  }

  @override
  Future<List<AttendanceSummaryModel>> getAttendanceSummary({
    required String classId,
    String? tanggalMulai,
    String? tanggalAkhir,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.attendanceRecap,
      queryParameters: {
        'kelas_id': classId,
        if (tanggalMulai != null) 'tanggal_mulai': tanggalMulai,
        if (tanggalAkhir != null) 'tanggal_akhir': tanggalAkhir,
      },
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => AttendanceSummaryModel.fromJson(json)).toList();
  }

  @override
  Future<void> submitAttendance(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return;
    final payload = {
      'kelas_id': data.first['kelas_id'],
      'tanggal': data.first['tanggal'],
      'data_absensi': data,
    };
    await _dioClient.post(ApiEndpoints.attendanceRecap, data: payload);
  }

  // ─── KEBERSIHAN ──────────────────────────────────────────────────
  @override
  Future<List<CleanlinessModel>> getCleanliness({String? classId}) async {
    final response = await _dioClient.get(
      ApiEndpoints.cleanliness,
      queryParameters: {if (classId != null) 'kelas_id': classId},
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => CleanlinessModel.fromJson(json)).toList();
  }

  @override
  Future<CleanlinessModel> createCleanliness({
    required Map<String, dynamic> data,
    PlatformFile? file,
  }) async {
    dynamic payload;
    Options? options;

    if (file != null) {
      final formData = FormData.fromMap(data);
      
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
        throw Exception('File tidak valid');
      }

      formData.files.add(MapEntry('foto', multipartFile));
      payload = formData;
      options = Options(headers: {'Content-Type': 'multipart/form-data'});
    } else {
      payload = data;
    }

    final response = await _dioClient.post(
      ApiEndpoints.cleanliness, 
      data: payload,
      options: options,
    );
    
    final raw = response.data;
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return CleanlinessModel.fromJson(raw['data']);
    }
    return CleanlinessModel.fromJson(raw);
  }

  @override
  Future<CleanlinessModel> updateCleanliness(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put('${ApiEndpoints.cleanliness}/$id', data: data);
    return CleanlinessModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteCleanliness(String id) async {
    await _dioClient.delete('${ApiEndpoints.cleanliness}/$id');
  }

  // ─── PARENTING ───────────────────────────────────────────────────
  @override
  Future<List<ParentingNoteModel>> getParentingNotes({String? classId, String? studentId}) async {
    final response = await _dioClient.get(
      ApiEndpoints.parenting,
      queryParameters: {
        if (classId != null) 'kelas_id': classId,
        if (studentId != null) 'siswa_id': studentId,
      },
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => ParentingNoteModel.fromJson(json)).toList();
  }

  @override
  Future<ParentingNoteModel> createParentingNote(Map<String, dynamic> data) async {
    final response = await _dioClient.post(ApiEndpoints.parenting, data: data);
    return ParentingNoteModel.fromJson(response.data['data']);
  }

  @override
  Future<ParentingNoteModel> updateParentingNote(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put('${ApiEndpoints.parenting}/$id', data: data);
    return ParentingNoteModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteParentingNote(String id) async {
    await _dioClient.delete('${ApiEndpoints.parenting}/$id');
  }

  // ─── REFLEKSI ────────────────────────────────────────────────────
  @override
  Future<List<ReflectionModel>> getReflections({String? classId}) async {
    final response = await _dioClient.get(
      ApiEndpoints.reflection,
      queryParameters: {if (classId != null) 'kelas_id': classId},
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => ReflectionModel.fromJson(json)).toList();
  }

  @override
  Future<ReflectionModel> createReflection(Map<String, dynamic> data) async {
    final response = await _dioClient.post(ApiEndpoints.reflection, data: data);
    return ReflectionModel.fromJson(response.data['data']);
  }

  @override
  Future<ReflectionModel> updateReflection(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put('${ApiEndpoints.reflection}/$id', data: data);
    return ReflectionModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteReflection(String id) async {
    await _dioClient.delete('${ApiEndpoints.reflection}/$id');
  }

  // ─── SURAT PANGGILAN ──────────────────────────────────────────────
  @override
  Future<List<SummonsLetterModel>> getSummonsLetters({String? classId, String? studentId}) async {
    final response = await _dioClient.get(
      ApiEndpoints.summons,
      queryParameters: {
        if (classId != null) 'kelas_id': classId,
        if (studentId != null) 'siswa_id': studentId,
      },
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => SummonsLetterModel.fromJson(json)).toList();
  }

  @override
  Future<SummonsLetterModel> createSummonsLetter(Map<String, dynamic> data) async {
    final response = await _dioClient.post(ApiEndpoints.summons, data: data);
    return SummonsLetterModel.fromJson(response.data['data']);
  }

  @override
  Future<SummonsLetterModel> updateSummonsLetter(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put('${ApiEndpoints.summons}/$id', data: data);
    return SummonsLetterModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteSummonsLetter(String id) async {
    await _dioClient.delete('${ApiEndpoints.summons}/$id');
  }

  // ─── NILAI (REKAP) ────────────────────────────────────────────────
  @override
  Future<List<GradeModel>> getGradesRecap({
    required String classId,
    String? semester,
    String? academicYear,
    String? mapelId,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.studentRekapNilai,
      queryParameters: {
        'kelas_id': classId,
        if (semester != null) 'semester': semester,
        if (academicYear != null) 'tahun_ajar': academicYear,
        if (mapelId != null) 'mapel_id': mapelId,
      },
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => GradeModel.fromJson(json)).toList();
  }

  @override
  Future<List<GradeModel>> getStudentGrades({
    required String studentId,
    String? semester,
    String? academicYear,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.studentRekapNilai,
      queryParameters: {
        'siswa_id': studentId,
        if (semester != null) 'semester': semester,
        if (academicYear != null) 'tahun_ajar': academicYear,
      },
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => GradeModel.fromJson(json)).toList();
  }
}
