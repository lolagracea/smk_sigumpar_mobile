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
  // ─── Attendance ───────────────────────────────────────────
  Future<PaginatedResponse<AttendanceModel>> getAttendanceRecap({
    required String classId,
    String? month,
    String? year,
    int page = 1,
  });

  Future<void> submitAttendance(Map<String, dynamic> data);

  // ─── Grades (lama) ────────────────────────────────────────
  Future<PaginatedResponse<GradeModel>> getGradesRecap({
    required String classId,
    String? semester,
    String? academicYear,
    int page = 1,
  });
  Future<CleanlinessModel> updateCleanliness(String id, Map<String, dynamic> data);
  Future<void> deleteCleanliness(String id);

  // ─── Grades (input nilai guru mapel) ─────────────────────
  Future<List<Map<String, dynamic>>> getGuruMapelAssignments();

  Future<List<Map<String, dynamic>>> getSiswaUntukInputNilai({
    required String kelasId,
    required String mapelId,
  });

  Future<List<Map<String, dynamic>>> getNilaiSiswa({
    required String kelasId,
    required String mapelId,
    required String tahunAjar,
    required String semester,
  });

  Future<void> createOrUpdateNilai({
    required String kelasId,
    required String mapelId,
    required String tahunAjar,
    required String semester,
    required Map<String, int> bobot,
    required List<Map<String, dynamic>> dataNilai,
  });

  // ─── Absensi Mapel (Guru Mapel) ───────────────────────────
  Future<List<Map<String, dynamic>>> getAbsensiMapelJadwal();

  Future<List<Map<String, dynamic>>> getAbsensiMapelSiswa({
    required String jadwalId,
  });

  Future<List<Map<String, dynamic>>> getAbsensiMapel({
    required String jadwalId,
    required String tanggal,
  });

  Future<void> createAbsensiMapel({
    required dynamic jadwalId,
    required String tanggal,
    required List<Map<String, dynamic>> dataAbsensi,
  });

  Future<List<Map<String, dynamic>>> getAbsensiMapelRekap({
    required String kelasId,
    required String mapelId,
    String? tanggalMulai,
    String? tanggalAkhir,
  });

  // ─── Cleanliness ─────────────────────────────────────────
  Future<PaginatedResponse<Map<String, dynamic>>> getCleanlinessRecap(
      {int page = 1});
  Future<Map<String, dynamic>> submitCleanliness(Map<String, dynamic> data);

  // ─── Parenting Notes ──────────────────────────────────────
  Future<PaginatedResponse<Map<String, dynamic>>> getParentingNotes(
      {int page = 1});
  Future<Map<String, dynamic>> createParentingNote(Map<String, dynamic> data);

  // ─── Homeroom Reflection ──────────────────────────────────
  Future<PaginatedResponse<Map<String, dynamic>>> getHomeroomReflections(
      {int page = 1});
  Future<Map<String, dynamic>> createHomeroomReflection(
      Map<String, dynamic> data);

  // ─── Summons Letter ───────────────────────────────────────
  Future<PaginatedResponse<Map<String, dynamic>>> getSummonsLetters(
      {int page = 1});
  Future<Map<String, dynamic>> createSummonsLetter(Map<String, dynamic> data);
}
