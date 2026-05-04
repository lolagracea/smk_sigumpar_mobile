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
  static const String subjects = '/academic/subjects';

  /// Route halaman daftar/manajemen pengumuman di mobile.
  ///
  /// Catatan:
  /// - Nama route lama tetap `announcements` supaya tidak merusak
  ///   AppDrawer dan app_router yang sudah memakai RouteNames.announcements.
  /// - Walaupun namanya announcements, UI tetap boleh menampilkan teks
  ///   "Pengumuman".
  static const String announcements = '/academic/announcements';

  /// Route detail pengumuman.
  ///
  /// Kita pakai path `/academic/pengumuman/:id` agar lebih dekat dengan
  /// flow web dan backend academic-service yang memakai istilah pengumuman.
  static const String announcementDetail = '/academic/pengumuman/:id';

  /// Helper untuk membuka detail pengumuman berdasarkan id.
  ///
  /// Contoh:
  /// context.go(RouteNames.announcementDetailPath('12'));
  static String announcementDetailPath(String id) {
    return '/academic/pengumuman/$id';
  }

  static const String schedules = '/academic/schedules';
  static const String letters = '/academic/letters';

  // ─── Student ───────────────────────────────────────────
  static const String student = '/student';
  static const String cleanlinessRecap = '/student/cleanliness';
  static const String parentingNotes = '/student/parenting-notes';
  static const String homeroomReflection = '/student/homeroom-reflection';
  static const String summonsLetter = '/student/summons';
  static const String attendanceRecap = '/student/attendance';

  /// Alias untuk absensi siswa.
  ///
  /// Dipakai oleh drawer/menu role tertentu agar tidak perlu route baru.
  static const String studentAttendance = attendanceRecap;

  static const String gradesRecap = '/student/grades';

  // ─── Learning ──────────────────────────────────────────
  static const String learning = '/learning';
  static const String teacherAttendance = '/learning/teacher-attendance';

  /// Alias untuk absensi guru.
  ///
  /// Dipakai oleh drawer/menu role tertentu agar tidak perlu route baru.
  static const String absensiGuru = teacherAttendance;

  static const String teachingNotes = '/learning/teaching-notes';
  static const String teacherEvaluation = '/learning/teacher-evaluation';
  static const String learningDevice = '/learning/devices';
  static const String principalReview = '/learning/principal-review';
  static const String vicePrincipalReview = '/learning/vice-principal-review';

  // ─── Vocational ────────────────────────────────────────
  static const String vocational = '/vocational';
  static const String scoutClasses = '/vocational/scout-classes';
  static const String scoutAttendance = '/vocational/scout-attendance';
  static const String scoutReport = '/vocational/scout-report';
  static const String pklLocationReport = '/vocational/pkl-location';
  static const String pklProgressReport = '/vocational/pkl-progress';
  static const String pklGradeInput = '/vocational/pkl-grade-input';

  // ─── Asset ─────────────────────────────────────────────
  static const String asset = '/asset';
  static const String submissionInfo = '/asset/submissions';
  static const String itemLoan = '/asset/loans';
  static const String equipmentSubmission = '/asset/equipment';
  static const String loanResponse = '/asset/loan-response';
  static const String treasurerResponse = '/asset/treasurer-response';
  static const String principalResponse = '/asset/principal-response';
}
