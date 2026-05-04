import '../models/attendance_model.dart';
import '../models/attendance_summary_model.dart';
import '../models/grade_model.dart';
import '../models/parenting_note_model.dart';
import '../models/student_model.dart';
import '../../core/network/api_response.dart';

abstract class StudentRepository {
  // Students
  Future<List<StudentModel>> getAllStudents();

  // Attendance
  Future<PaginatedResponse<AttendanceModel>> getAttendanceRecap({
    required String classId,
    String? month,
    String? year,
    int page = 1,
  });
  
  Future<List<AttendanceSummaryModel>> getAttendanceSummary({
    required String classId,
    String? month,
    String? year,
  });

  Future<void> submitAttendance(List<Map<String, dynamic>> data);

  // Grades
  Future<PaginatedResponse<GradeModel>> getGradesRecap({
    required String classId,
    String? semester,
    String? academicYear,
    int page = 1,
  });
  
  Future<List<GradeModel>> getStudentGrades({
    required String studentId,
    String? semester,
    String? academicYear,
  });

  Future<GradeModel> submitGrade(Map<String, dynamic> data);
  Future<GradeModel> updateGrade(String id, Map<String, dynamic> data);

  // Cleanliness
  Future<PaginatedResponse<Map<String, dynamic>>> getCleanlinessRecap({int page = 1});
  Future<Map<String, dynamic>> submitCleanliness(Map<String, dynamic> data);

  // Parenting Notes
  Future<PaginatedResponse<ParentingNoteModel>> getParentingNotes({int page = 1});
  Future<ParentingNoteModel> createParentingNote(Map<String, dynamic> data);

  // Homeroom Reflection
  Future<PaginatedResponse<Map<String, dynamic>>> getHomeroomReflections({int page = 1});
  Future<Map<String, dynamic>> createHomeroomReflection(Map<String, dynamic> data);

  // Summons Letter
  Future<PaginatedResponse<Map<String, dynamic>>> getSummonsLetters({int page = 1});
  Future<Map<String, dynamic>> createSummonsLetter(Map<String, dynamic> data);
}
