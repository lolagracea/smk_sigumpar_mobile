// lib/features/guru_mapel/absensi_guru/data/repositories/absensi_guru_repository.dart
import 'package:dio/dio.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../models/absensi_guru_model.dart';

class AbsensiGuruRepository {
  final Dio _dio;

  AbsensiGuruRepository() : _dio = ApiClient().learning;

  String get _base => '${AppConstants.learningServiceUrl}/absensi-guru';

  Future<List<AbsensiGuruModel>> getAll({String? tanggal}) async {
    final response = await _dio.get(
      _base,
      queryParameters: tanggal != null ? {'tanggal': tanggal} : null,
    );
    final data = response.data;
    final list = (data['data'] as List?) ?? (data as List? ?? []);
    return list
        .map((e) => AbsensiGuruModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AbsensiGuruModel> create(AbsensiGuruModel model) async {
    final response = await _dio.post(_base, data: model.toJson());
    final data = response.data;
    return AbsensiGuruModel.fromJson(
        (data['data'] ?? data) as Map<String, dynamic>);
  }

  Future<AbsensiGuruModel> update(int id, AbsensiGuruModel model) async {
    final response =
    await _dio.put('$_base/$id', data: model.toJson());
    final data = response.data;
    return AbsensiGuruModel.fromJson(
        (data['data'] ?? data) as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete('$_base/$id');
  }
}