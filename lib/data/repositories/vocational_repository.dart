import '../../core/network/api_response.dart';

abstract class VocationalRepository {
  // ── Scout Classes (Regu/Kelas) ────────────────────────────────
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutClasses({int page = 1});
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutAttendance({int page = 1, String? classId});
  Future<void> submitScoutAttendance(Map<String, dynamic> data);
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutReports({int page = 1});
  Future<Map<String, dynamic>> createScoutReport(Map<String, dynamic> data);

  // ── Absensi Pramuka (NEW — mirror web) ───────────────────────
  /// GET /api/vocational/kelas — daftar kelas vokasional
  Future<List<Map<String, dynamic>>> getKelasVokasional();

  /// GET /api/vocational/siswa?kelas_id=X — daftar siswa per kelas
  Future<List<Map<String, dynamic>>> getSiswaPramuka({required String kelasId});

  /// GET /api/vocational/absensi?kelas_id=X&tanggal=Y — riwayat absensi
  Future<List<Map<String, dynamic>>> getRiwayatAbsensiPramuka({
    String? kelasId,
    String? tanggal,
  });

  /// POST /api/vocational/absensi — simpan absensi bulk
  Future<void> submitAbsensiPramukaBulk(Map<String, dynamic> payload);

  /// GET /api/vocational/absensi/rekap?kelas_id=X&tanggal_mulai=Y&tanggal_akhir=Z
  Future<List<Map<String, dynamic>>> getRekapAbsensiPramuka({
    required String kelasId,
    String? tanggalMulai,
    String? tanggalAkhir,
  });

  // ── PKL (Praktik Kerja Lapangan) ─────────────────────────────
  Future<PaginatedResponse<Map<String, dynamic>>> getPklLocationReports({int page = 1});
  Future<Map<String, dynamic>> submitPklLocationReport(Map<String, dynamic> data);
  Future<PaginatedResponse<Map<String, dynamic>>> getPklProgressReports({int page = 1});
  Future<Map<String, dynamic>> submitPklProgressReport(Map<String, dynamic> data);
}