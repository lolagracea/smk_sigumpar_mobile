import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/attendance_model.dart';
import '../models/attendance_summary_model.dart';
import '../models/grade_model.dart';
import '../models/parenting_note_model.dart';
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

  @override
  Future<PaginatedResponse<AttendanceModel>> getAttendanceRecap({
    required String classId,
    String? month,
    String? year,
    int page = 1,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.attendanceRecap,
      queryParameters: {
        'class_id': classId,
        'page': page,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      },
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => AttendanceModel.fromJson(json),
    );
  }

  @override
  Future<List<AttendanceSummaryModel>> getAttendanceSummary({
    required String classId,
    String? month,
    String? year,
  }) async {
    final response = await _dioClient.get(
      '${ApiEndpoints.attendanceRecap}/summary',
      queryParameters: {
        'class_id': classId,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      },
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => AttendanceSummaryModel.fromJson(json)).toList();
  }

  @override
  Future<void> submitAttendance(List<Map<String, dynamic>> data) async {
    await _dioClient.post(ApiEndpoints.attendanceRecap, data: {'records': data});
  }

  @override
  Future<PaginatedResponse<GradeModel>> getGradesRecap({
    required String classId,
    String? semester,
    String? academicYear,
    int page = 1,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.studentRekapNilai,
      queryParameters: {
        'class_id': classId,
        'page': page,
        if (semester != null) 'semester': semester,
        if (academicYear != null) 'academic_year': academicYear,
      },
    );
    return PaginatedResponse.fromJson(response.data, (json) => GradeModel.fromJson(json));
  }

  @override
  Future<List<GradeModel>> getStudentGrades({
    required String studentId,
    String? semester,
    String? academicYear,
  }) async {
    final response = await _dioClient.get(
      '${ApiEndpoints.studentRekapNilai}/student/$studentId',
      queryParameters: {
        if (semester != null) 'semester': semester,
        if (academicYear != null) 'academic_year': academicYear,
      },
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => GradeModel.fromJson(json)).toList();
  }

  @override
  Future<GradeModel> submitGrade(Map<String, dynamic> data) async {
    final response = await _dioClient.post(ApiEndpoints.studentRekapNilai, data: data);
    return GradeModel.fromJson(response.data['data']);
  }

  @override
  Future<GradeModel> updateGrade(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put('${ApiEndpoints.studentRekapNilai}/$id', data: data);
    return GradeModel.fromJson(response.data['data']);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getCleanlinessRecap({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.cleanliness, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> submitCleanliness(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.cleanliness, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<ParentingNoteModel>> getParentingNotes({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.parenting, queryParameters: {'page': page});
    
    if (r.data['data'] is List) {
      final List rawList = r.data['data'];
      return PaginatedResponse<ParentingNoteModel>(
        items: rawList.map((e) => ParentingNoteModel.fromJson(e as Map<String, dynamic>)).toList(),
        currentPage: 1,
        lastPage: 1,
        perPage: rawList.length,
        total: rawList.length,
      );
    }
    
    return PaginatedResponse.fromJson(r.data, (j) => ParentingNoteModel.fromJson(j as Map<String, dynamic>));
  }

  @override
  Future<ParentingNoteModel> createParentingNote(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.parenting, data: data);
    final responseData = r.data['data'] ?? r.data;
    return ParentingNoteModel.fromJson(responseData as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getHomeroomReflections({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.reflection, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createHomeroomReflection(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.reflection, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getSummonsLetters({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.summons, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createSummonsLetter(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.summons, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }
}
