// lib/features/guru_mapel/absensi_siswa/data/repositories/absensi_siswa_repository.dart
import 'package:dio/dio.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../shared/models/shared_models.dart';
import '../models/absensi_siswa_model.dart';

class AbsensiSiswaRepository {
  final Dio _dio;

  AbsensiSiswaRepository() : _dio = ApiClient().academic;

  Future<List<KelasModel>> getKelas() async {
    final res = await _dio.get(
        '${AppConstants.academicServiceUrl}/kelas');
    final list =
        (res.data['data'] as List?) ?? (res.data as List? ?? []);
    return list.map((e) => KelasModel.fromJson(e)).toList();
  }

  Future<List<MapelModel>> getMapelByKelas(int kelasId) async {
    final res = await _dio.get(
      '${AppConstants.academicServiceUrl}/mapel',
      queryParameters: {'kelas_id': kelasId},
    );
    final list =
        (res.data['data'] as List?) ?? (res.data as List? ?? []);
    return list.map((e) => MapelModel.fromJson(e)).toList();
  }

  Future<List<SiswaModel>> getSiswaByKelas(int kelasId) async {
    final res = await _dio.get(
      '${AppConstants.academicServiceUrl}/siswa',
      queryParameters: {'kelas_id': kelasId},
    );
    final list =
        (res.data['data'] as List?) ?? (res.data as List? ?? []);
    return list.map((e) => SiswaModel.fromJson(e)).toList();
  }

  Future<List<AbsensiSiswaModel>> getAbsensi({
    required int kelasId,
    required String tanggal,
    int? mapelId,
  }) async {
    final res = await _dio.get(
      '${AppConstants.academicServiceUrl}/absensi-siswa',
      queryParameters: {
        'kelas_id': kelasId,
        'tanggal' : tanggal,
        if (mapelId != null) 'mapel_id': mapelId,
      },
    );
    final list =
        (res.data['data'] as List?) ?? (res.data as List? ?? []);
    return list.map((e) => AbsensiSiswaModel.fromJson(e)).toList();
  }

  Future<void> saveBulk(List<AbsensiSiswaModel> items) async {
    await _dio.post(
      '${AppConstants.academicServiceUrl}/absensi-siswa/bulk',
      data: {'data': items.map((e) => e.toJson()).toList()},
    );
  }
}