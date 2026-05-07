import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
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

  // ─── DOWNLOAD FILE ─────────────────────────────────────────────
  // Mengunduh file dari microservice menggunakan Dio + Authorization header.
  // Microservice membaca token dari header "Authorization: Bearer <token>",
  // bukan dari query param, sehingga url_launcher tidak bisa digunakan.
  //
  // Alur:
  //   1. Ambil token dari SecureStorage
  //   2. Request GET ke endpoint download dengan Authorization header
  //   3. Simpan bytes ke file sementara di cache directory
  //   4. Buka file menggunakan url_launcher (file:// URI)

  Future<void> downloadFile({
    required String url,
    required String fileName,
  }) async {
    final fullUrl = url.startsWith('http')
        ? url
        : '${ApiEndpoints.baseUrl}$url';

    final token = await _secureStorage.getAccessToken();

    // Ambil bytes file dari server dengan Authorization header
    final dio = Dio();
    final response = await dio.get<List<int>>(
      fullUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      ),
    );

    final bytes = Uint8List.fromList(response.data!);

    if (kIsWeb) {
      // ── Web: buat Blob URL dan klik programatically ──
      // Tidak bisa akses dart:io di web, gunakan url_launcher dengan data URL
      // sebagai fallback terbaik yang tersedia tanpa package tambahan.
      final base64 = _base64Encode(bytes);
      final mimeType = _mimeFromFileName(fileName);
      final dataUrl = 'data:$mimeType;base64,$base64';
      final uri = Uri.parse(dataUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    // ── Mobile/Desktop: simpan ke cache dir lalu buka ──
    final tempDir = Directory.systemTemp;
    final safeFileName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final filePath = p.join(tempDir.path, safeFileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    final fileUri = Uri.file(filePath);
    if (await canLaunchUrl(fileUri)) {
      await launchUrl(fileUri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── helpers ──────────────────────────────────────────────────

  String _base64Encode(Uint8List bytes) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final result = StringBuffer();
    int i = 0;
    while (i < bytes.length) {
      final b0 = bytes[i++];
      final b1 = i < bytes.length ? bytes[i++] : 0;
      final b2 = i < bytes.length ? bytes[i++] : 0;
      result.write(chars[(b0 >> 2) & 0x3f]);
      result.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3f]);
      result.write(chars[((b1 << 2) | (b2 >> 6)) & 0x3f]);
      result.write(chars[b2 & 0x3f]);
    }
    final s = result.toString();
    final pad = (3 - bytes.length % 3) % 3;
    return pad == 0 ? s : s.substring(0, s.length - pad) + ('=' * pad);
  }

  String _mimeFromFileName(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.doc':
        return 'application/msword';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}