// ─────────────────────────────────────────────────────────────────────────────
// lib/data/services/vocational_service.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../repositories/vocational_repository.dart';
import '../models/laporan_kegiatan_model.dart';

class VocationalService implements VocationalRepository {
  final DioClient _dioClient;
  VocationalService({required DioClient dioClient}) : _dioClient = dioClient;

  // ── Scout Classes (existing) ─────────────────────────────────
  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutClasses({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.scoutGroups, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutAttendance({int page = 1, String? classId}) async {
    final r = await _dioClient.get(ApiEndpoints.scoutAttendance, queryParameters: {
      'page': page,
      if (classId != null) 'class_id': classId,
    });
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<void> submitScoutAttendance(Map<String, dynamic> data) async {
    await _dioClient.post(ApiEndpoints.scoutAttendance, data: data);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutReports({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.activityReport, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createScoutReport(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.activityReport, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  // ── Absensi Pramuka (mirror web vocationalApi) ────────────────

  @override
  Future<List<Map<String, dynamic>>> getKelasVokasional() async {
    final r = await _dioClient.get(ApiEndpoints.vocationalClasses);
    final data = r.data['data'];
    if (data is List) return data.map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getSiswaPramuka({required String kelasId}) async {
    final r = await _dioClient.get(ApiEndpoints.vocationalStudents, queryParameters: {'kelas_id': kelasId});
    final data = r.data['data'];
    if (data is List) return data.map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getRiwayatAbsensiPramuka({String? kelasId, String? tanggal}) async {
    final params = <String, dynamic>{};
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    final r = await _dioClient.get(ApiEndpoints.scoutAttendance, queryParameters: params);
    final data = r.data['data'];
    if (data is List) return data.map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  @override
  Future<void> submitAbsensiPramukaBulk(Map<String, dynamic> payload) async {
    await _dioClient.post(ApiEndpoints.scoutAttendance, data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getRekapAbsensiPramuka({
    required String kelasId,
    String? tanggalMulai,
    String? tanggalAkhir,
  }) async {
    final params = <String, dynamic>{'kelas_id': kelasId};
    if (tanggalMulai != null && tanggalMulai.isNotEmpty) params['tanggal_mulai'] = tanggalMulai;
    if (tanggalAkhir != null && tanggalAkhir.isNotEmpty) params['tanggal_akhir'] = tanggalAkhir;
    final r = await _dioClient.get(ApiEndpoints.scoutAttendanceRecap, queryParameters: params);
    final data = r.data['data'];
    if (data is List) return data.map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  // ── Laporan Kegiatan Pramuka (NEW — mirror web vocationalApi) ─

  @override
  Future<List<LaporanKegiatanModel>> getAllLaporanKegiatan() async {
    // GET /api/vocational/laporan-kegiatan
    // Response: { success: true, data: [...] }
    final r = await _dioClient.get(ApiEndpoints.activityReport);
    final raw = r.data['data'];
    if (raw is List) {
      return raw.map((e) => LaporanKegiatanModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<LaporanKegiatanModel> createLaporanKegiatan(FormData formData) async {
    // POST /api/vocational/laporan-kegiatan  (multipart/form-data)
    // Fields: judul, deskripsi, tanggal, file_laporan (optional)
    final r = await _dioClient.postFormData(ApiEndpoints.activityReport, formData: formData);
    final data = r.data['data'];
    return LaporanKegiatanModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteLaporanKegiatan(int id) async {
    // DELETE /api/vocational/laporan-kegiatan/:id
    await _dioClient.delete('${ApiEndpoints.activityReport}/$id');
  }

  @override
  Future<Response<List<int>>> viewLaporanKegiatanFile(int id) async {
    // GET /api/vocational/laporan-kegiatan/:id/view
    // Returns raw binary file (PDF / image / etc)
    return await _dioClient.dio.get<List<int>>(
      '${ApiEndpoints.activityReport}/$id/view',
      options: Options(responseType: ResponseType.bytes),
    );
  }

  @override
  Future<Response<List<int>>> downloadLaporanKegiatanFile(int id) async {
    // GET /api/vocational/laporan-kegiatan/:id/download
    return await _dioClient.dio.get<List<int>>(
      '${ApiEndpoints.activityReport}/$id/download',
      options: Options(responseType: ResponseType.bytes),
    );
  }

  // ── PKL (existing) ───────────────────────────────────────────
  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getPklLocationReports({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.pklLocation, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> submitPklLocationReport(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.pklLocation, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getPklProgressReports({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.pklProgress, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> submitPklProgressReport(Map<String, dynamic> data) async {
    final r = await _dioClient.post(ApiEndpoints.pklProgress, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }
}