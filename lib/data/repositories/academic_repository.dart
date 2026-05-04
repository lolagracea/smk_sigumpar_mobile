import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/user_search_model.dart';
import '../../core/network/api_response.dart';
import 'package:file_picker/file_picker.dart';
import '../models/arsip_surat_model.dart';
import '../models/mapel_assignment_model.dart';
import '../models/schedule_model.dart';
import '../models/subject_model.dart';

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

  // ─── Students ────────────────────────────────────────────
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

  // ─── Schedules / Jadwal Mengajar ─────────────────────────
  Future<List<ScheduleModel>> getSchedules({
    String? classId,
    String? teacherId,
  });

  Future<ScheduleModel> createSchedule(Map<String, dynamic> data);

  Future<ScheduleModel> updateSchedule(
      String id,
      Map<String, dynamic> data,
      );

  Future<void> deleteSchedule(String id);

  Future<List<UserSearchModel>> searchGuruMapel(String query);

  Future<List<MapelAssignmentModel>> getMapelByGuru(String guruId);

  // ─── Letters / Arsip Surat ──────────────────────────────
  Future<PaginatedResponse<ArsipSuratModel>> getLetters({
    int page = 1,
  });

  Future<ArsipSuratModel> createLetter({
    required String nomorSurat,
    required PlatformFile file,
  });

  Future<ArsipSuratModel> updateLetter({
    required String id,
    required String nomorSurat,
    PlatformFile? file,
  });

  Future<void> deleteLetter(String id);

  // ─── Subjects / Mata Pelajaran ──────────────────────────
  Future<PaginatedResponse<SubjectModel>> getSubjects({
    int page = 1,
    String? classId,
    String? teacherId,
    String? search,
  });

  Future<SubjectModel> createSubject(Map<String, dynamic> data);

  Future<SubjectModel> updateSubject(
      String id,
      Map<String, dynamic> data,
      );

  Future<void> deleteSubject(String id);
}