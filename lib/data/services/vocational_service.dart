import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/secure_storage.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_endpoints.dart';
import '../repositories/vocational_repository.dart';

class VocationalService implements VocationalRepository {
  final DioClient _dioClient;
  final SecureStorage _secureStorage;
  VocationalService({required DioClient dioClient})
      : _dioClient = dioClient,
        _secureStorage = sl<SecureStorage>();

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutClasses({int page = 1}) async {
    final r = await _dioClient.get(ApiEndpoints.scoutGroups, queryParameters: {'page': page});
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutAttendance({int page = 1, String? classId}) async {
    final r = await _dioClient.get(ApiEndpoints.scoutAttendance, queryParameters: {'page': page, if (classId != null) 'class_id': classId});
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

  // ─── PRAMUKA: RAW DATA METHODS ────────────────────────────────

  Future<Map<String, dynamic>> getRawKelasVokasi() async {
    final r = await _dioClient.get(ApiEndpoints.vocationalClasses);
    return Map<String, dynamic>.from(r.data ?? {});
  }

  Future<Map<String, dynamic>> getRawSiswaVokasi({String? kelasId}) async {
    final params = <String, dynamic>{};
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    final r = await _dioClient.get(ApiEndpoints.vocationalStudents, queryParameters: params);
    return Map<String, dynamic>.from(r.data ?? {});
  }

  // ─── PRAMUKA: ABSENSI ─────────────────────────────────────────

  Future<void> submitAbsensiPramuka(Map<String, dynamic> data) async {
    await _dioClient.post(ApiEndpoints.scoutAttendance, data: data);
  }

  Future<Map<String, dynamic>> getRawAbsensiPramuka({String? kelasId, String? tanggal}) async {
    final params = <String, dynamic>{};
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    final r = await _dioClient.get(ApiEndpoints.scoutAttendance, queryParameters: params);
    return Map<String, dynamic>.from(r.data ?? {});
  }

  Future<Map<String, dynamic>> getRawRekapAbsensiPramuka({
    required String kelasId,
    String? tanggalMulai,
    String? tanggalAkhir,
  }) async {
    final params = <String, dynamic>{'kelas_id': kelasId};
    if (tanggalMulai != null && tanggalMulai.isNotEmpty) params['tanggal_mulai'] = tanggalMulai;
    if (tanggalAkhir != null && tanggalAkhir.isNotEmpty) params['tanggal_akhir'] = tanggalAkhir;
    final r = await _dioClient.get(ApiEndpoints.scoutAttendanceRecap, queryParameters: params);
    return Map<String, dynamic>.from(r.data ?? {});
  }

  // ─── PRAMUKA: SILABUS ─────────────────────────────────────────

  Future<Map<String, dynamic>> getRawSilabus() async {
    final r = await _dioClient.get(ApiEndpoints.syllabus);
    return Map<String, dynamic>.from(r.data ?? {});
  }

  Future<void> createSilabus({
    required String kelasId,
    required String namaKelas,
    required String judulKegiatan,
    required String tanggal,
    PlatformFile? file,
  }) async {
    final formData = FormData.fromMap({
      'kelas_id': kelasId,
      'nama_kelas': namaKelas,
      'judul_kegiatan': judulKegiatan,
      'tanggal': tanggal,
      if (file != null && file.bytes != null)
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    await _dioClient.postFormData(ApiEndpoints.syllabus, formData: formData);
  }

  Future<void> deleteSilabus(dynamic id) async {
    await _dioClient.delete('${ApiEndpoints.syllabus}/$id');
  }

  // ─── PRAMUKA: LAPORAN KEGIATAN ────────────────────────────────

  Future<Map<String, dynamic>> getRawLaporanKegiatan() async {
    final r = await _dioClient.get(ApiEndpoints.activityReport);
    return Map<String, dynamic>.from(r.data ?? {});
  }

  Future<void> createLaporanKegiatan({
    required String judul,
    required String deskripsi,
    required String tanggal,
    PlatformFile? file,
  }) async {
    final formData = FormData.fromMap({
      'judul': judul,
      'deskripsi': deskripsi,
      'tanggal': tanggal,
      if (file != null && file.bytes != null)
        'file_laporan': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    await _dioClient.postFormData(ApiEndpoints.activityReport, formData: formData);
  }

  Future<void> deleteLaporanKegiatan(dynamic id) async {
    await _dioClient.delete('${ApiEndpoints.activityReport}/$id');
  }

  // ─── DOWNLOAD FILE ────────────────────────────────────────────

  Future<void> downloadFile({required String url, required String fileName}) async {
    final fullUrl = url.startsWith('http') ? url : '${ApiEndpoints.baseUrl}$url';
    // Try opening with token in URL via url_launcher; browser will send auth header
    // For web/mobile we append token as query param fallback since url_launcher can't set headers
    final token = await _secureStorage.getAccessToken();
    String launchUrl = fullUrl;
    if (token != null && token.isNotEmpty) {
      final separator = fullUrl.contains('?') ? '&' : '?';
      launchUrl = '$fullUrl${separator}token=$token';
    }
    final uri = Uri.parse(launchUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
