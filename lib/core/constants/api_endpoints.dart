import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // ═══════════════════════════════════════════════════════════════
  // === ENVIRONMENT CONFIG ===
  // ═══════════════════════════════════════════════════════════════
  //
  // Ganti _useProduction = true kalau sudah deploy ke server publik.
  //
  // DEVELOPMENT (lokal):
  //   - Web / iOS Simulator : localhost
  //   - Android Emulator    : 10.0.2.2  (alias localhost dari emulator)
  //   - Android Device fisik: IP WiFi laptop (contoh: 10.172.198.20)
  //
  // PRODUCTION:
  //   - Semua platform pakai URL publik (_productionBase)
  // ═══════════════════════════════════════════════════════════════

  /// Set ke [true] kalau sudah deploy ke server publik.
  static const bool _useProduction = false;

  /// IP WiFi laptop kamu (untuk Android device fisik saat development).
  /// Cek dengan: ipconfig (Windows) → lihat IPv4 WiFi
  static const String _localDeviceIp = '10.172.198.20';

  /// URL server publik setelah deploy (Railway / VPS / dll).
  /// Contoh Railway : 'https://smk-backend.up.railway.app'
  /// Contoh VPS     : 'https://api.smkn1sigumpar.sch.id'
  static const String _productionBase = 'https://YOUR_PRODUCTION_URL_HERE';

  // ═══════════════════════════════════════════════════════════════
  // === BASE URLs (otomatis, jangan diubah) ===
  // ═══════════════════════════════════════════════════════════════

  /// Base URL untuk Backend Microservices (via Nginx Gateway port 8001)
  static String get baseUrl {
    if (_useProduction) return '$_productionBase:8001';
    if (kIsWeb) return 'http://localhost:8001';
    return 'http://$_localDeviceIp:8001';
  }

  // ═══════════════════════════════════════════════════════════════
  // === KEYCLOAK CONFIG ===
  // ═══════════════════════════════════════════════════════════════

  /// Client ID Keycloak (sesuai konfigurasi di docker-compose & realm)
  static const String keycloakClientId = 'smk-sigumpar';

  /// Realm Keycloak
  static const String keycloakRealm = 'smk-sigumpar';

  /// Base URL Keycloak (auto-switch berdasarkan environment & platform)
  static String get keycloakBaseUrl {
    if (_useProduction) return '$_productionBase:8080';
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://$_localDeviceIp:8080';
  }

  /// Endpoint untuk login & refresh token
  static String get keycloakTokenUrl =>
      '$keycloakBaseUrl/realms/$keycloakRealm/protocol/openid-connect/token';

  /// Endpoint untuk fetch user profile
  static String get keycloakUserInfoUrl =>
      '$keycloakBaseUrl/realms/$keycloakRealm/protocol/openid-connect/userinfo';

  /// Endpoint untuk logout (invalidate Keycloak session)
  static String get keycloakLogoutUrl =>
      '$keycloakBaseUrl/realms/$keycloakRealm/protocol/openid-connect/logout';

  // ═══════════════════════════════════════════════════════════════
  // === AUTH SERVICE ===
  // ═══════════════════════════════════════════════════════════════
  static const String authVerify = '/api/auth/verify';
  static const String authUsers = '/api/auth/';
  static const String authUsersSearch = '/api/auth/users/search';

  // ═══════════════════════════════════════════════════════════════
  // === ACADEMIC SERVICE ===
  // ═══════════════════════════════════════════════════════════════
  static const String classes = '/api/academic/kelas';
  static const String classesByWali = '/api/academic/kelas/wali'; // + /:waliId
  static const String students = '/api/academic/siswa';
  static const String teachers = '/api/academic/guru';
  static const String teachersSearch = '/api/academic/guru/search';
  static const String subjects = '/api/academic/mapel';
  static const String subjectsByGuru = '/api/academic/mapel/guru'; // + /:guruId
  static const String schedules = '/api/academic/jadwal';
  static const String piket = '/api/academic/piket';
  static const String upacara = '/api/academic/upacara';
  static const String announcements = '/api/academic/pengumuman';
  static const String letters = '/api/academic/arsip-surat';
  static const String grades = '/api/academic/nilai';
  static const String gradesBulk = '/api/academic/nilai/bulk';
  static const String gradesStudentsByClass =
      '/api/academic/nilai/siswa-by-kelas';
  static const String gradesExportExcel = '/api/academic/nilai/export-excel';
  static const String studentAttendance = '/api/academic/absensi-siswa';
  static const String teacherClasses = '/api/academic/teacher/classes';
  static const String classStudents =
      '/api/academic/classes'; // + /:classId/students
  static const String attendanceClass =
      '/api/academic/attendance/class'; // + /:classId
  static const String attendanceBulk = '/api/academic/attendance/bulk';
  static const String kepsekRekapAbsensi =
      '/api/academic/kepsek/rekap-absensi-siswa';
  static const String kepsekRekapNilai = '/api/academic/kepsek/rekap-nilai';
  static const String kepsekStatistik = '/api/academic/kepsek/statistik';
  static const String kepsekRekapNilaiFinal =
      '/api/academic/kepsek/rekap-nilai-final';
  static const String wakilJadwal = '/api/academic/wakil/jadwal';
  static const String wakilJadwalRekap =
      '/api/academic/wakil/jadwal/rekap-hari';
  static const String wakilParenting =
      '/api/academic/wakil/parenting-monitoring';

  // ─── WAKIL KEPSEK ENDPOINTS ──────────────────────────────
  static const String wakilKurikulum = '/api/learning/perangkat';
  static const String wakilProgramKerja = '/api/academic/wakil/program-kerja';
  static const String wakilSupervisi = '/api/academic/wakil/supervisi';
  static const String absensiGuru = '/api/learning/absensi-guru';

  // ═══════════════════════════════════════════════════════════════
  // === STUDENT SERVICE ===
  // ═══════════════════════════════════════════════════════════════
  static const String cleanliness = '/api/student/kebersihan';
  static const String studentGrades = '/api/student/nilai';
  static const String studentGradesAssignments =
      '/api/student/nilai/assignments';
  static const String studentGradesSiswa = '/api/student/nilai/siswa';
  static const String studentRekapNilai = '/api/student/rekap-nilai';
  static const String parenting = '/api/student/parenting';
  static const String reflection = '/api/student/refleksi';
  static const String summons = '/api/student/surat-panggilan';
  static const String attendanceRecap = '/api/student/rekap-kehadiran';
  static const String absensiMapel = '/api/student/absensi-mapel';
  static const String absensiMapelJadwal = '/api/student/absensi-mapel/jadwal';
  static const String absensiMapelRekap = '/api/student/absensi-mapel/rekap';
  static const String kepsekRekapStudentAttendance =
      '/api/student/kepala-sekolah/rekap-absensi';

  // ═══════════════════════════════════════════════════════════════
  // === LEARNING SERVICE ===
  // ═══════════════════════════════════════════════════════════════
  static const String teacherAttendance = '/api/learning/absensi-guru';
  static const String teachingNotes = '/api/learning/catatan-mengajar';
  static const String teacherEvaluation = '/api/learning/evaluasi-guru';
  static const String learningDevices = '/api/learning/perangkat';

  static String learningDeviceDownload(int id) =>
      '$learningDevices/$id/download';
  static String learningDeviceView(int id) => '$learningDevices/$id/view';
  static String learningDeviceReviewKepsek(int id) =>
      '$learningDevices/$id/review-kepsek';
  static String learningDeviceReviewWakasek(int id) =>
      '$learningDevices/$id/review-wakasek';

  // ═══════════════════════════════════════════════════════════════
  // === VOCATIONAL SERVICE ===
  // ═══════════════════════════════════════════════════════════════
  static const String scoutGroups = '/api/vocational/regu';
  static const String scoutAvailableStudents =
      '/api/vocational/regu/siswa-tersedia';
  static const String scoutAssign = '/api/vocational/regu/assign';
  static const String scoutAttendance = '/api/vocational/absensi';
  static const String scoutAttendanceRecap = '/api/vocational/absensi/rekap';
  static const String syllabus = '/api/vocational/silabus';
  static const String activityReport = '/api/vocational/laporan-kegiatan';
  static const String vocationalStudents = '/api/vocational/siswa';
  static const String vocationalClasses = '/api/vocational/kelas';
  static const String pklLocation = '/api/vocational/pkl/lokasi';
  static const String pklProgress = '/api/vocational/pkl/progres';
  static const String pklGrades = '/api/vocational/pkl/nilai';

  // ═══════════════════════════════════════════════════════════════
  // === HELPERS untuk Dynamic Endpoints ===
  // ═══════════════════════════════════════════════════════════════
  static String getKelasByWaliId(String waliId) => '$classesByWali/$waliId';
  static String getClassStudents(int classId) =>
      '$classStudents/$classId/students';
  static String getAttendanceByClass(int classId) =>
      '$attendanceClass/$classId';
  static String getSubjectsByGuruId(String guruId) =>
      '$subjectsByGuru/$guruId';

  // ═══════════════════════════════════════════════════════════════
  // === ENDPOINT TAMBAHAN ===
  // ═══════════════════════════════════════════════════════════════
  static const String profile = '/api/auth/profile';
  static const String logout = '/api/auth/logout';

  // ═══════════════════════════════════════════════════════════════
  // === ASSET SERVICE ===
  // ═══════════════════════════════════════════════════════════════
  static const String submissionInfo = '/api/asset/informasi-pengajuan';
  static const String itemLoan = '/api/asset/peminjaman-barang';
  static const String equipmentSubmission = '/api/asset/pengajuan-alat';
  static const String loanResponse = '/api/asset/respon-peminjaman';
  static const String treasurerResponse = '/api/asset/respon-bendahara';
  static const String principalResponse = '/api/asset/respon-kepsek';
}