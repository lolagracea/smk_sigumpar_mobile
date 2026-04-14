class ApiEndpoints {
  ApiEndpoints._();

  // Base URL — ganti sesuai environment
  static const String baseUrl = 'https://api.smkn1sigumpar.sch.id/api/v1';

  // ─── Auth ──────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/profile';

  // ─── Academic ──────────────────────────────────────────
  static const String classes = '/academic/classes';
  static const String students = '/academic/students';
  static const String teachers = '/academic/teachers';
  static const String announcements = '/academic/announcements';
  static const String schedules = '/academic/schedules';
  static const String letters = '/academic/letters';

  // ─── Student ───────────────────────────────────────────
  static const String cleanlinessRecap = '/student/cleanliness';
  static const String parentingNotes = '/student/parenting-notes';
  static const String homeroomReflection = '/student/homeroom-reflection';
  static const String summonsLetter = '/student/summons';
  static const String attendanceRecap = '/student/attendance';
  static const String gradesRecap = '/student/grades';

  // ─── Learning ──────────────────────────────────────────
  static const String teacherAttendance = '/learning/teacher-attendance';
  static const String teachingNotes = '/learning/teaching-notes';
  static const String teacherEvaluation = '/learning/teacher-evaluation';
  static const String learningDevice = '/learning/devices';
  static const String principalReview = '/learning/principal-review';
  static const String vicePrincipalReview = '/learning/vice-principal-review';

  // ─── Vocational ────────────────────────────────────────
  static const String scoutClasses = '/vocational/scout-classes';
  static const String scoutAttendance = '/vocational/scout-attendance';
  static const String scoutReport = '/vocational/scout-report';
  static const String pklLocationReport = '/vocational/pkl-location';
  static const String pklProgressReport = '/vocational/pkl-progress';

  // ─── Asset ─────────────────────────────────────────────
  static const String submissionInfo = '/asset/submissions';
  static const String itemLoan = '/asset/loans';
  static const String equipmentSubmission = '/asset/equipment';
  static const String loanResponse = '/asset/loan-response';
  static const String treasurerResponse = '/asset/treasurer-response';
  static const String principalResponse = '/asset/principal-response';
}
