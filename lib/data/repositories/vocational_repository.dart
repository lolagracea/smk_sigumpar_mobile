import '../../core/network/api_response.dart';

abstract class VocationalRepository {
  // Scout
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutClasses(
      {int page = 1});
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutAttendance(
      {int page = 1, String? classId});
  Future<void> submitScoutAttendance(Map<String, dynamic> data);
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutReports(
      {int page = 1});
  Future<Map<String, dynamic>> createScoutReport(Map<String, dynamic> data);

  // PKL (Praktik Kerja Lapangan)
  Future<PaginatedResponse<Map<String, dynamic>>> getPklLocationReports(
      {int page = 1});
  Future<Map<String, dynamic>> submitPklLocationReport(
      Map<String, dynamic> data);
  Future<PaginatedResponse<Map<String, dynamic>>> getPklProgressReports(
      {int page = 1});
  Future<Map<String, dynamic>> submitPklProgressReport(
      Map<String, dynamic> data);

  // PKL Grades
  Future<PaginatedResponse<Map<String, dynamic>>> getPklGrades({int page = 1});
  Future<void> submitPklGrade(Map<String, dynamic> data);
}
