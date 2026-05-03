// lib/features/guru_mapel/input_nilai/data/repositories/nilai_repository.dart
import 'package:dio/dio.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../shared/models/shared_models.dart';
import '../models/nilai_model.dart';

class NilaiRepository {
  final Dio _dio;

  NilaiRepository() : _dio = ApiClient().academic;

  Future<List<KelasModel>> getKelas() async {
    final res = await _dio.get('${AppConstants.academicServiceUrl}/kelas');
    final list = (res.data['data'] as List?) ?? (res.data as List? ?? []);
    return list.map((e) => KelasModel.fromJson(e)).toList();
  }

  Future<List<MapelModel>> getMapel() async {
    final res = await _dio.get('${AppConstants.academicServiceUrl}/mapel');
    final list = (res.data['data'] as List?) ?? (res.data as List? ?? []);
    return list.map((e) => MapelModel.fromJson(e)).toList();
  }

  Future<List<NilaiSiswaModel>> getSiswaWithNilai({
    required int kelasId,
    int? mapelId,
    String? tahunAjar,
  }) async {
    final res = await _dio.get(
      '${AppConstants.academicServiceUrl}/nilai/siswa-by-kelas',
      queryParameters: {
        'kelas_id'  : kelasId,
        if (mapelId   != null) 'mapel_id'  : mapelId,
        if (tahunAjar != null) 'tahun_ajar': tahunAjar,
      },
    );
    final list = (res.data['data'] as List?) ?? (res.data as List? ?? []);
    return list.map((e) => NilaiSiswaModel.fromJson(e)).toList();
  }

  Future<void> saveBulk(
      List<NilaiSiswaModel> rows, int kelasId, int? mapelId, String tahunAjar) async {
    await _dio.post('${AppConstants.academicServiceUrl}/nilai/bulk', data: {
      'kelas_id'  : kelasId,
      if (mapelId != null) 'mapel_id': mapelId,
      'tahun_ajar': tahunAjar,
      'data'      : rows.map((e) => e.toJson()).toList(),
    });
  }
}
