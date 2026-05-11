import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';

import '../../core/constants/api_endpoints.dart';
import '../repositories/vocational_repository.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/pkl_location_model.dart';
import '../models/pkl_progress_model.dart';
import '../models/pkl_grade_model.dart';

class VocationalService implements VocationalRepository {
  final DioClient _dioClient;
  VocationalService({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutClasses({
    int page = 1,
  }) async {
    final r = await _dioClient.get(
      ApiEndpoints.scoutGroups,
      queryParameters: {'page': page},
    );
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutAttendance({
    int page = 1,
    String? classId,
  }) async {
    final r = await _dioClient.get(
      ApiEndpoints.scoutAttendance,
      queryParameters: {'page': page, if (classId != null) 'class_id': classId},
    );
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<void> submitScoutAttendance(Map<String, dynamic> data) async {
    await _dioClient.post(ApiEndpoints.scoutAttendance, data: data);
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> getScoutReports({
    int page = 1,
  }) async {
    final r = await _dioClient.get(
      ApiEndpoints.activityReport,
      queryParameters: {'page': page},
    );
    return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createScoutReport(
    Map<String, dynamic> data,
  ) async {
    final r = await _dioClient.post(ApiEndpoints.activityReport, data: data);
    return r.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResponse<ClassModel>> getPklClasses({
    int page = 1,
    String? search,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.vocationalClasses,
      queryParameters: {
        'page': page,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final raw = response.data;
    List<dynamic> rows = [];

    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) {
        rows = raw['data'] as List;
      } else if (raw['data'] is Map<String, dynamic> &&
          raw['data']['data'] is List) {
        rows = raw['data']['data'] as List;
      }
    }

    final items = rows
        .map((item) => ClassModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<ClassModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<PaginatedResponse<StudentModel>> getPklStudents({
    int page = 1,
    String? classId,
    String? search,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.vocationalStudents,
      queryParameters: {
        'page': page,
        if (classId != null && classId.isNotEmpty) 'kelas_id': classId,
      },
    );

    final raw = response.data;
    List<dynamic> rows = [];

    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) {
        rows = raw['data'] as List;
      } else if (raw['data'] is Map<String, dynamic> &&
          raw['data']['data'] is List) {
        rows = raw['data']['data'] as List;
      }
    }

    final keyword = search?.trim().toLowerCase();

    final items = rows
        .map(
      (item) => StudentModel.fromJson(Map<String, dynamic>.from(item as Map)),
    )
        .where((siswa) {
      if (keyword == null || keyword.isEmpty) return true;
      return siswa.nisn.toLowerCase().contains(keyword) ||
          siswa.namaLengkap.toLowerCase().contains(keyword) ||
          siswa.namaKelas.toLowerCase().contains(keyword);
    }).toList();

    return PaginatedResponse<StudentModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<PaginatedResponse<PklLocationModel>> getPklLocationReports({
    int page = 1,
    String? classId,
    String? studentId,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.pklLocation,
      queryParameters: {
        'page': page,
        if (classId != null && classId.isNotEmpty) 'kelas_id': classId,
        if (studentId != null && studentId.isNotEmpty) 'siswa_id': studentId,
      },
    );

    final raw = response.data;
    List<dynamic> rows = [];

    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) {
        rows = raw['data'] as List;
      } else if (raw['data'] is Map<String, dynamic> &&
          raw['data']['data'] is List) {
        rows = raw['data']['data'] as List;
      }
    }

    final items = rows
        .map((item) => PklLocationModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<PklLocationModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<PklLocationModel> submitPklLocationReport(
    Map<String, dynamic> data,
  ) async {
    await _dioClient.post(ApiEndpoints.pklLocation, data: data);
    return PklLocationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      siswaId: data['siswa_id']?.toString() ?? '',
      namaSiswa: data['nama_siswa']?.toString() ?? '',
      kelasId: data['kelas_id']?.toString() ?? '',
      namaKelas: data['nama_kelas']?.toString() ?? '',
      namaPerusahaan: data['nama_perusahaan']?.toString() ?? '',
      alamatPerusahaan: data['alamat_perusahaan']?.toString() ?? '',
      posisiSiswa: data['posisi_siswa']?.toString(),
      pembimbingIndustri: data['pembimbing_industri']?.toString(),
      kontakPembimbing: data['kontak_pembimbing']?.toString(),
      tanggalMulai: data['tanggal_mulai']?.toString(),
      tanggalSelesai: data['tanggal_selesai']?.toString(),
      deskripsi: data['deskripsi']?.toString(),
      foto: data['foto']?.toString(),
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<PaginatedResponse<PklProgressModel>> getPklProgressReports({
    int page = 1,
    String? classId,
    String? studentId,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.pklProgress,
      queryParameters: {
        'page': page,
        if (classId != null && classId.isNotEmpty) 'kelas_id': classId,
        if (studentId != null && studentId.isNotEmpty) 'siswa_id': studentId,
      },
    );

    final raw = response.data;
    List<dynamic> rows = [];

    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) {
        rows = raw['data'] as List;
      } else if (raw['data'] is Map<String, dynamic> &&
          raw['data']['data'] is List) {
        rows = raw['data']['data'] as List;
      }
    }

    final items = rows
        .map((item) => PklProgressModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<PklProgressModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<PklProgressModel> submitPklProgressReport(
    Map<String, dynamic> data,
  ) async {
    await _dioClient.post(ApiEndpoints.pklProgress, data: data);
    return PklProgressModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      siswaId: data['siswa_id']?.toString() ?? '',
      namaSiswa: data['nama_siswa']?.toString() ?? '',
      kelasId: data['kelas_id']?.toString() ?? '',
      namaKelas: data['nama_kelas']?.toString() ?? '',
      pklLokasiId: data['pkl_lokasi_id']?.toString() ?? '',
      judulKegiatan: data['judul_kegiatan']?.toString() ?? '',
      deskripsiKegiatan: data['deskripsi_kegiatan']?.toString() ?? '',
      tanggalKegiatan: data['tanggal_kegiatan']?.toString() ?? '',
      mingguKe: data['minggu_ke'] is int
          ? data['minggu_ke']
          : int.tryParse(data['minggu_ke']?.toString() ?? '') ?? 1,
      jamMulai: data['jam_mulai']?.toString(),
      jamSelesai: data['jam_selesai']?.toString(),
      buktiFoto: data['bukti_foto']?.toString(),
      capaian: data['capaian']?.toString(),
      penilaian: data['penilaian']?.toString(),
      kendala: data['kendala']?.toString(),
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<PaginatedResponse<PklGradeModel>> getPklGrades({
    int page = 1,
    String? classId,
    String? studentId,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.pklGrades,
      queryParameters: {
        'page': page,
        if (classId != null && classId.isNotEmpty) 'kelas_id': classId,
        if (studentId != null && studentId.isNotEmpty) 'siswa_id': studentId,
      },
    );

    final raw = response.data;
    List<dynamic> rows = [];

    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      if (raw['data_nilai'] is List) {
        rows = raw['data_nilai'] as List;
      } else if (raw['data'] is List) {
        rows = raw['data'] as List;
      } else if (raw['data'] is Map<String, dynamic> &&
          raw['data']['data'] is List) {
        rows = raw['data']['data'] as List;
      } else if (raw['data'] is Map<String, dynamic> &&
          raw['data']['data_nilai'] is List) {
        rows = raw['data']['data_nilai'] as List;
      }
    }

    final items = rows
        .map((item) => PklGradeModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<PklGradeModel>(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: items.length,
      total: items.length,
    );
  }

  @override
  Future<void> submitPklGrade(Map<String, dynamic> data) async {
    final kelasId = data['kelas_id'];
    final payload = {
      'kelas_id': kelasId,
      'data_nilai': [data],
    };
    await _dioClient.post(ApiEndpoints.pklGrades, data: payload);
  }
}
