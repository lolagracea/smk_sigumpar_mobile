import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Samakan dengan Web: Base URL hanya sampai port Gateway
  static const String baseUrl = kIsWeb
      ? 'http://localhost:8001'
      : 'http://10.0.2.2:8001';

  // ─── Auth ──────────────────────────────────────────────
  // Di Web: /auth/profile
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/profile';

  // ─── Academic ──────────────────────────────────────────
  // Gunakan awalan /api untuk rute yang membutuhkan verifikasi Nginx
  static const String classes = '/api/academic/classes';
  static const String students = '/api/academic/students';
  static const String teachers = '/api/academic/teachers';
  static const String announcements = '/api/academic/announcements';
  static const String schedules = '/api/academic/schedules';
  static const String letters = '/api/academic/letters';

  // ─── Student ───────────────────────────────────────────
  // PENTING: Backend menggunakan 'students' (jamak), Nginx menggunakan 'student' (tunggal)
  // Untuk mobile, tembak langsung ke rute backend yang benar lewat /api
  static const String cleanlinessRecap = '/api/students/cleanliness';
  static const String parentingNotes = '/api/students/parenting-notes';
  static const String homeroomReflection = '/api/students/homeroom-reflection';
  static const String summonsLetter = '/api/students/summons';
  static const String attendanceRecap = '/api/students/attendance';
  static const String gradesRecap = '/api/students/grades';

  // ─── Learning ──────────────────────────────────────────
  static const String teacherAttendance = '/api/learning/teacher-attendance';
  static const String teachingNotes = '/api/learning/teaching-notes';
  static const String teacherEvaluation = '/api/learning/teacher-evaluation';
  static const String learningDevice = '/api/learning/devices';
  static const String principalReview = '/api/learning/principal-review';
  static const String vicePrincipalReview = '/api/learning/vice-principal-review';

  // ─── Vocational ────────────────────────────────────────
  static const String scoutClasses = '/api/vocational/scout-classes';
  static const String scoutAttendance = '/api/vocational/scout-attendance';
  static const String scoutReport = '/api/vocational/scout-report';
  static const String pklLocationReport = '/api/vocational/pkl-location';
  static const String pklProgressReport = '/api/vocational/pkl-progress';

  // ─── Asset ─────────────────────────────────────────────
  static const String submissionInfo = '/api/asset/submissions';
  static const String itemLoan = '/api/asset/loans';
  static const String equipmentSubmission = '/api/asset/equipment';
  static const String loanResponse = '/api/asset/loan-response';
  static const String treasurerResponse = '/api/asset/treasurer-response';
  static const String principalResponse = '/api/asset/principal-response';
}