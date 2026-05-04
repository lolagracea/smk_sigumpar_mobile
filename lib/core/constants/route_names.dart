class RouteNames {
  RouteNames._();

  // ─── Auth ──────────────────────────────────────────────
  static const String login = '/login';
  static const String profile = '/profile';

  // ─── Home ──────────────────────────────────────────────
  static const String home = '/home';

  // ─── Academic ──────────────────────────────────────────
  static const String academic = '/academic';
  static const String classes = '/academic/classes';
  static const String students = '/academic/students';
  static const String teachers = '/academic/teachers';
  static const String announcements = '/academic/announcements';
  static const String schedules = '/academic/schedules';
  static const String letters = '/academic/letters';

  // ─── Student ───────────────────────────────────────────
  static const String student = '/student';
  static const String cleanlinessRecap = '/student/cleanliness';
  static const String parentingNotes = '/student/parenting-notes';
  static const String homeroomReflection = '/student/homeroom-reflection';
  static const String summonsLetter = '/student/summons';
  static const String attendanceRecap = '/student/attendance';
  static const String gradesRecap = '/student/grades';

  // ─── Learning ──────────────────────────────────────────
  static const String learning = '/learning';
  static const String teacherAttendance = '/learning/teacher-attendance';
  static const String teachingNotes = '/learning/teaching-notes';
  static const String teacherEvaluation = '/learning/teacher-evaluation';
  static const String learningDevice = '/learning/devices';
  static const String principalReview = '/learning/principal-review';
  static const String vicePrincipalReview = '/learning/vice-principal-review';

  // ─── Vocational ────────────────────────────────────────
  static const String vocational = '/vocational';
  // scoutClasses DIHAPUS — fitur Kelas Pramuka tidak ada di web
  static const String scoutAttendance = '/vocational/scout-attendance';
  static const String scoutReport = '/vocational/scout-report';
  static const String pklLocationReport = '/vocational/pkl-location';
  static const String pklProgressReport = '/vocational/pkl-progress';

}