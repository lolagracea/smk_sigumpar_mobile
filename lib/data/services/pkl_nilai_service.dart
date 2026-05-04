// lib/features/vokasi/pkl_nilai/data/services/pkl_nilai_service.dart

import 'package:smk_sigumpar/core/network/dio_client.dart';
import 'package:smk_sigumpar/core/constants/api_endpoints.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/pkl_input_nilai_model.dart';
import '../repositories/pkl_nilai_repository.dart';

class PklNilaiService implements PklNilaiRepository {
  final DioClient _dioClient;

  PklNilaiService({required DioClient dioClient}) : _dioClient = dioClient;

  // ─── GET semua kelas ──────────────────────────────────────
  @override
  Future<List<ClassModel>> getKelas() async {
    final response = await _dioClient.get(ApiEndpoints.classes);
    final raw = response.data;

    // Handle berbagai format response: {data: {data: []}} atau {data: []}
    List<dynamic> list;
    if (raw['data'] is Map && raw['data']['data'] is List) {
      list = raw['data']['data'] as List;
    } else if (raw['data'] is List) {
      list = raw['data'] as List;
    } else {
      list = [];
    }
    return list
        .map((e) => ClassModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── GET siswa + nilai PKL by kelas ──────────────────────
  @override
  Future<List<PklNilaiSiswaModel>> getSiswaWithNilaiPkl({
    required int kelasId,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.pklGrades,
      queryParameters: {'kelas_id': kelasId},
    );
    final raw = response.data;

    List<dynamic> list;
    if (raw['data'] is Map && raw['data']['data'] is List) {
      list = raw['data']['data'] as List;
    } else if (raw['data'] is List) {
      list = raw['data'] as List;
    } else {
      list = [];
    }
    return list
        .map((e) => PklNilaiSiswaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── POST bulk simpan nilai PKL ───────────────────────────
  @override
  Future<void> saveBulkNilaiPkl({
    required int kelasId,
    required List<PklNilaiSiswaModel> rows,
  }) async {
    await _dioClient.post(
      // Endpoint: POST /api/vocational/pkl/nilai/bulk
      // (tambahkan ke ApiEndpoints jika belum ada)
      '${ApiEndpoints.pklGrades}/bulk',
      data: {
        'kelas_id': kelasId,
        'data': rows.map((e) => e.toJson()).toList(),
      },
    );
  }
}
