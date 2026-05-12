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

  // ─── Attendance ───────────────────────────────────────────
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
    return PaginatedResponse.fromJson(
      response.data,
          (json) => AttendanceModel.fromJson(json),
    );
  }

  @override
  // ✅ IKUTI TEAM LEAD: parameter Map + rethrow
  Future<void> submitAttendance(Map<String, dynamic> data) async {
    try {
      await _dioClient.post(ApiEndpoints.absensiMapel, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Grades (lama) ────────────────────────────────────────
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
    return PaginatedResponse.fromJson(
        response.data, (json) => GradeModel.fromJson(json));
  }

  @override
  Future<GradeModel> submitGrade(Map<String, dynamic> data) async {
    final response =
    await _dioClient.post(ApiEndpoints.studentRekapNilai, data: data);
    return GradeModel.fromJson(response.data['data']);
  }

  @override
  Future<GradeModel> updateGrade(String id, Map<String, dynamic> data) async {
    final response = await _dioClient
        .put('${ApiEndpoints.studentRekapNilai}/$id', data: data);
    return GradeModel.fromJson(response.data['data']);
  }

  // ─── Grades (input nilai guru mapel) ─────────────────────

  @override
  Future<List<Map<String, dynamic>>> getGuruMapelAssignments() async {
    final response = await _dioClient.get(
      ApiEndpoints.studentGradesAssignments,
    );
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    final list = data['data'] ?? data['assignments'] ?? [];
    return (list as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getSiswaUntukInputNilai({
    required String kelasId,
    required String mapelId,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.studentGradesSiswa,
      queryParameters: {'kelas_id': kelasId, 'mapel_id': mapelId},
    );
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    final list = data['data'] ?? data['siswa'] ?? [];
    return (list as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getNilaiSiswa({
    required String kelasId,
    required String mapelId,
    required String tahunAjar,
    required String semester,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.studentGrades,
      queryParameters: {
        'kelas_id': kelasId,
        'mapel_id': mapelId,
        'tahun_ajar': tahunAjar,
        'semester': semester,
      },
    );
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    final list = data['data'] ?? data['nilai'] ?? [];
    return (list as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> createOrUpdateNilai({
    required String kelasId,
    required String mapelId,
    required String tahunAjar,
    required String semester,
    required Map<String, int> bobot,
    required List<Map<String, dynamic>> dataNilai,
  }) async {
    await _dioClient.post(
      ApiEndpoints.studentGrades,
      data: {
        'kelas_id': int.tryParse(kelasId) ?? kelasId,
        'mapel_id': int.tryParse(mapelId) ?? mapelId,
        'tahun_ajar': tahunAjar,
        'semester': semester,
        'bobot': {
          'tugas': bobot['tugas'],
          'kuis': bobot['kuis'],
          'uts': bobot['uts'],
          'uas': bobot['uas'],
          'praktik': bobot['praktik'],
        },
        'data_nilai': dataNilai,
      },
    );
  }

  // ─── Absensi Mapel (Guru Mapel) ───────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getAbsensiMapelJadwal() async {
    final response = await _dioClient.get(ApiEndpoints.absensiMapelJadwal);
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    final list = data['data'] ?? [];
    return (list as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getAbsensiMapelSiswa({
    required String jadwalId,
  }) async {
    final response = await _dioClient.get(
      '${ApiEndpoints.absensiMapel}/siswa',
      queryParameters: {'jadwal_id': jadwalId},
    );
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    final list = data['data'] ?? [];
    return (list as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getAbsensiMapel({
    required String jadwalId,
    required String tanggal,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.absensiMapel,
      queryParameters: {'jadwal_id': jadwalId, 'tanggal': tanggal},
    );
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    final list = data['data'] ?? [];
    return (list as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> createAbsensiMapel({
    required dynamic jadwalId,
    required String tanggal,
    required List<Map<String, dynamic>> dataAbsensi,
  }) async {
    await _dioClient.post(
      ApiEndpoints.absensiMapel,
      data: {
        'jadwal_id': jadwalId,
        'tanggal': tanggal,
        'data_absensi': dataAbsensi,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getAbsensiMapelRekap({
    required String kelasId,
    required String mapelId,
    String? tanggalMulai,
    String? tanggalAkhir,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.absensiMapelRekap,
      queryParameters: {
        'kelas_id': kelasId,
        'mapel_id': mapelId,
        if (tanggalMulai != null) 'tanggal_mulai': tanggalMulai,
        if (tanggalAkhir != null) 'tanggal_akhir': tanggalAkhir,
      },
    );
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    final list = data['data'] ?? [];
    return (list as List).cast<Map<String, dynamic>>();
  }

  // ─── Cleanliness ─────────────────────────────────────────
  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getCleanlinessRecap(
      {int page = 1}) async {
    final r = await _dioClient
        .get(ApiEndpoints.cleanliness, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> submitCleanliness(
      Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.cleanliness, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  // ─── Parenting Notes ──────────────────────────────────────
  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getParentingNotes(
      {int page = 1}) async {
    final r = await _dioClient
        .get(ApiEndpoints.parenting, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createParentingNote(
      Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.parenting, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  // ─── Homeroom Reflection ──────────────────────────────────
  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getHomeroomReflections(
      {int page = 1}) async {
    final r = await _dioClient
        .get(ApiEndpoints.reflection, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createHomeroomReflection(
      Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.reflection, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  // ─── Summons Letter ───────────────────────────────────────
  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getSummonsLetters(
      {int page = 1}) async {
    final r = await _dioClient
        .get(ApiEndpoints.summons, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createSummonsLetter(
      Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.summons, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }
}