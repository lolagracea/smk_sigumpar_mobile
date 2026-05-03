// lib/features/guru_mapel/perangkat/data/perangkat_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import 'perangkat_model.dart';

class PerangkatRepository {
  final Dio _dio;

  PerangkatRepository() : _dio = ApiClient().learning;

  Future<List<PerangkatModel>> getAll() async {
    final res = await _dio.get('${AppConstants.learningServiceUrl}/perangkat');
    final list = (res.data['data'] as List?) ?? (res.data as List? ?? []);
    return list.map((e) => PerangkatModel.fromJson(e)).toList();
  }

  Future<void> upload({
    required String namaDokumen,
    required String jenisDokumen,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'nama_dokumen' : namaDokumen,
      'jenis_dokumen': jenisDokumen,
      'file'         : await MultipartFile.fromFile(filePath, filename: fileName),
    });
    await _dio.post('${AppConstants.learningServiceUrl}/perangkat',
        data: formData);
  }

  Future<void> delete(int id) async {
    await _dio.delete('${AppConstants.learningServiceUrl}/perangkat/$id');
  }
}
