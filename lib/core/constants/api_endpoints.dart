import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = kIsWeb
      ? 'http://localhost:8001'
      : 'http://10.0.2.2:8001';

  // ─── Auth ──────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/profile';
  static const String users = '/api/auth/users';

  // ─── Academic ──────────────────────────────────────────
  // Disesuaikan dengan backend website
  static const String classes = '/api/academic/kelas';
  static const String students = '/api/academic/siswa';
  static const String teachers = '/api/academic/guru';
  static const String announcements = '/api/academic/pengumuman';
  static const String schedules = '/api/academic/jadwal';
  static const String letters = '/api/academic/arsip-surat';

  // ─── Student ───────────────────────────────────────────
  static const String cleanlinessRecap = '/api/student/kebersihan';
  static const String parentingNotes = '/api/student/parenting';
  static const String homeroomReflection = '/api/student/refleksi';
  static const String summonsLetter = '/api/student/surat-panggilan';
  static const String attendanceRecap = '/api/student/rekap-kehadiran';
  static const String gradesRecap = '/api/student/nilai';

  // ─── Learning ──────────────────────────────────────────
  static const String teacherAttendance = '/api/learning/absensi-guru';
  static const String teachingNotes = '/api/learning/catatan-mengajar';
  static const String teacherEvaluation = '/api/learning/evaluasi-guru';
  static const String learningDevice = '/api/learning/perangkat';
  static const String principalReview = '/api/learning/perangkat';
  static const String vicePrincipalReview = '/api/learning/perangkat';

  // ─── Vocational ────────────────────────────────────────
  static const String scoutClasses = '/api/vocational/kelas';
  static const String scoutAttendance = '/api/vocational/absensi';
  static const String scoutReport = '/api/vocational/laporan-kegiatan';
  static const String pklLocationReport = '/api/vocational/pkl/lokasi';
  static const String pklProgressReport = '/api/vocational/pkl/progres';

}