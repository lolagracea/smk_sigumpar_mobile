import 'package:file_picker/file_picker.dart';
import '../models/attendance_model.dart';
import '../models/attendance_summary_model.dart';
import '../models/grade_model.dart';
import '../models/parenting_note_model.dart';
import '../models/cleanliness_model.dart';
import '../models/reflection_model.dart';
import '../models/summons_letter_model.dart';
import '../models/student_model.dart';
import '../../core/network/api_response.dart';

abstract class StudentRepository {
  Future<List<StudentModel>> getAllStudents();

  // ─── Attendance ──────────────────────────────────────────
  Future<PaginatedResponse<AttendanceModel>> getAttendanceRecap({required String classId, String? date});
  Future<List<AttendanceSummaryModel>> getAttendanceSummary({required String classId, String? tanggalMulai, String? tanggalAkhir});
  Future<void> submitAttendance(List<Map<String, dynamic>> data);

  // ─── Cleanliness (CRUD) ───────────────────────────────────
  Future<List<CleanlinessModel>> getCleanliness({String? classId});
  Future<CleanlinessModel> createCleanliness({
    required Map<String, dynamic> data,
    PlatformFile? file,
  });
  Future<CleanlinessModel> updateCleanliness(String id, Map<String, dynamic> data);
  Future<void> deleteCleanliness(String id);

  // ─── Parenting (CRUD) ─────────────────────────────────────
  Future<List<ParentingNoteModel>> getParentingNotes({String? classId, String? studentId});
  Future<ParentingNoteModel> createParentingNote(Map<String, dynamic> data);
  Future<ParentingNoteModel> updateParentingNote(String id, Map<String, dynamic> data);
  Future<void> deleteParentingNote(String id);

  // ─── Reflection (CRUD) ────────────────────────────────────
  Future<List<ReflectionModel>> getReflections({String? classId});
  Future<ReflectionModel> createReflection(Map<String, dynamic> data);
  Future<ReflectionModel> updateReflection(String id, Map<String, dynamic> data);
  Future<void> deleteReflection(String id);

  // ─── Summons Letter (CRUD) ────────────────────────────────
  Future<List<SummonsLetterModel>> getSummonsLetters({String? classId, String? studentId});
  Future<SummonsLetterModel> createSummonsLetter(Map<String, dynamic> data);
  Future<SummonsLetterModel> updateSummonsLetter(String id, Map<String, dynamic> data);
  Future<void> deleteSummonsLetter(String id);

  // ─── Grades ──────────────────────────────────────────────
  Future<List<GradeModel>> getGradesRecap({
    required String classId, 
    String? semester, 
    String? academicYear,
    String? mapelId,
  });
  Future<List<GradeModel>> getStudentGrades({required String studentId, String? semester, String? academicYear});
}
