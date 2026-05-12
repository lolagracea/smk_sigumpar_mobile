import 'package:file_picker/file_picker.dart';
import '../../core/network/api_response.dart';
import '../models/attendance_model.dart';
import '../models/attendance_summary_model.dart';
import '../models/grade_model.dart';
import '../models/parenting_note_model.dart';
import '../models/cleanliness_model.dart';
import '../models/reflection_model.dart';
import '../models/summons_letter_model.dart';
import '../models/student_model.dart';

abstract class StudentRepository {
  // ═══════════════════════════════════════════════════════════════
  // === FITUR WALI KELAS (CRUD penuh) ===
  // ═══════════════════════════════════════════════════════════════

  // ─── Students (general) ─────────────────────────────────────────
  Future<List<StudentModel>> getAllStudents();

  // ─── Attendance Summary (rekap H/I/S/A/T per siswa) ────────────
  Future<List<AttendanceSummaryModel>> getAttendanceSummary({
    required String classId,
    String? tanggalMulai,
    String? tanggalAkhir,
  });

  // ─── Cleanliness (CRUD) ─────────────────────────────────────────
  Future<List<CleanlinessModel>> getCleanliness({String? classId});
  Future<CleanlinessModel> createCleanliness({
    required Map<String, dynamic> data,
    PlatformFile? file,
  });
  Future<CleanlinessModel> updateCleanliness(
      String id,
      Map<String, dynamic> data,
      );
  Future<void> deleteCleanliness(String id);

  // ─── Parenting Notes (CRUD) ─────────────────────────────────────
  Future<List<ParentingNoteModel>> getParentingNotes({
    String? classId,
    String? studentId,
  });
  Future<ParentingNoteModel> createParentingNote(Map<String, dynamic> data);
  Future<ParentingNoteModel> updateParentingNote(
      String id,
      Map<String, dynamic> data,
      );
  Future<void> deleteParentingNote(String id);

  // ─── Reflection (CRUD) ──────────────────────────────────────────
  Future<List<ReflectionModel>> getReflections({String? classId});
  Future<ReflectionModel> createReflection(Map<String, dynamic> data);
  Future<ReflectionModel> updateReflection(
      String id,
      Map<String, dynamic> data,
      );
  Future<void> deleteReflection(String id);

  // ─── Summons Letter (CRUD) ──────────────────────────────────────
  Future<List<SummonsLetterModel>> getSummonsLetters({
    String? classId,
    String? studentId,
  });
  Future<SummonsLetterModel> createSummonsLetter(Map<String, dynamic> data);
  Future<SummonsLetterModel> updateSummonsLetter(
      String id,
      Map<String, dynamic> data,
      );
  Future<void> deleteSummonsLetter(String id);

  // ─── Grades Recap (read-only, List) ─────────────────────────────
  Future<List<GradeModel>> getGradesRecap({
    required String classId,
    String? semester,
    String? academicYear,
    String? mapelId,
  });

  Future<List<GradeModel>> getStudentGrades({
    required String studentId,
    String? semester,
    String? academicYear,
  });

  // ═══════════════════════════════════════════════════════════════
  // === FITUR GURU MAPEL (Punya HEAD — Tetap Dipertahankan) ===
  // ═══════════════════════════════════════════════════════════════

  // ─── Attendance Recap (lama, pagination) ────────────────────────
  Future<PaginatedResponse<AttendanceModel>> getAttendanceRecap({
    required String classId,
    String? date,
  });

  /// Submit absensi (single payload Map sesuai struktur backend).
  Future<void> submitAttendance(Map<String, dynamic> data);

  // ─── Grades (input nilai guru mapel) ────────────────────────────
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

  // ─── Absensi Mapel (Guru Mapel) ─────────────────────────────────
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
}