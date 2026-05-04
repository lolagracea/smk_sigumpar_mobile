import '../../core/network/api_response.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/pkl_location_model.dart';
import '../models/pkl_progress_model.dart';

abstract class VocationalRepository {
  // Scout
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutClasses({
    int page = 1,
  });
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutAttendance({
    int page = 1,
    String? classId,
  });
  Future<void> submitScoutAttendance(Map<String, dynamic> data);
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutReports({
    int page = 1,
  });
  Future<Map<String, dynamic>> createScoutReport(Map<String, dynamic> data);

  // PKL (Praktik Kerja Lapangan)
  Future<PaginatedResponse<ClassModel>> getPklClasses({
    int page = 1,
    String? search,
  });
  Future<PaginatedResponse<StudentModel>> getPklStudents({
    int page = 1,
    String? classId,
    String? search,
  });
  Future<PaginatedResponse<PklLocationModel>> getPklLocationReports({
    int page = 1,
    String? classId,
    String? studentId,
  });
  Future<PklLocationModel> submitPklLocationReport(Map<String, dynamic> data);
  Future<PaginatedResponse<PklProgressModel>> getPklProgressReports({
    int page = 1,
    String? classId,
    String? studentId,
  });
  Future<PklProgressModel> submitPklProgressReport(Map<String, dynamic> data);
}
