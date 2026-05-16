// lib/data/services/kelola_akun_service.dart

import '../../core/network/dio_client.dart';
import '../models/kelola_akun_model.dart';
import '../repositories/kelola_akun_repository.dart';

class KelolaAkunService implements KelolaAkunRepository {
  final DioClient _dioClient;

  KelolaAkunService({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<List<KelolaAkunModel>> getUsers() async {
    final response = await _dioClient.get('/api/auth/users');
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => KelolaAkunModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<String>> getUserRoles(String idKeycloak) async {
    final response =
        await _dioClient.get('/api/auth/users/$idKeycloak/roles');
    final data = response.data as Map<String, dynamic>;
    final rawData = data['data'];
    if (rawData is List) {
      return rawData.map((e) => e.toString()).toList();
    }
    return [];
  }

  @override
  Future<void> createUser(CreateAkunPayload payload) async {
    await _dioClient.post(
      '/api/auth/users',
      data: payload.toJson(),
    );
  }

  @override
  Future<void> updateUser(String idKeycloak, UpdateAkunPayload payload) async {
    await _dioClient.put(
      '/api/auth/users/$idKeycloak',
      data: payload.toJson(),
    );
  }

  @override
  Future<void> deleteUser(String idKeycloak) async {
    await _dioClient.delete('/api/auth/users/$idKeycloak');
  }
}