import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/user_search_model.dart';
import '../../core/network/api_response.dart';

abstract class AcademicRepository {
  // Classes
  Future<PaginatedResponse<ClassModel>> getClasses({
    int page = 1,
    String? search,
  });

  Future<ClassModel> getClassById(String id);

  Future<ClassModel> createClass(Map<String, dynamic> data);

  Future<ClassModel> updateClass(String id, Map<String, dynamic> data);

  Future<void> deleteClass(String id);

  Future<List<UserSearchModel>> searchWaliKelas(String query);

  // Students
  Future<PaginatedResponse<StudentModel>> getStudents({
    int page = 1,
    String? classId,
    String? search,
  });

  Future<StudentModel> getStudentById(String id);

  Future<StudentModel> createStudent(Map<String, dynamic> data);

  Future<StudentModel> updateStudent(String id, Map<String, dynamic> data);

  Future<void> deleteStudent(String id);

  // Teachers
  Future<PaginatedResponse<TeacherModel>> getTeachers({
    int page = 1,
    String? search,
  });

  Future<TeacherModel> getTeacherById(String id);

  // Announcements
  Future<PaginatedResponse<Map<String, dynamic>>> getAnnouncements({
    int page = 1,
  });

  Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> data);

  Future<Map<String, dynamic>> updateAnnouncement(
      String id,
      Map<String, dynamic> data,
      );

  Future<void> deleteAnnouncement(String id);

  // Schedules
  Future<List<Map<String, dynamic>>> getSchedules({
    String? classId,
    String? teacherId,
  });

  // Letters
  Future<PaginatedResponse<Map<String, dynamic>>> getLetters({
    int page = 1,
  });
}