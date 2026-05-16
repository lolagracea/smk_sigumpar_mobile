// lib/data/repositories/kelola_akun_repository.dart

import '../models/kelola_akun_model.dart';

abstract class KelolaAkunRepository {
  /// Ambil semua user — GET /api/auth/users
  Future<List<KelolaAkunModel>> getUsers();

  /// Ambil roles user tertentu — GET /api/auth/users/:id/roles
  Future<List<String>> getUserRoles(String idKeycloak);

  /// Buat akun baru — POST /api/auth/users
  Future<void> createUser(CreateAkunPayload payload);

  /// Update akun — PUT /api/auth/users/:id
  Future<void> updateUser(String idKeycloak, UpdateAkunPayload payload);

  /// Hapus akun — DELETE /api/auth/users/:id
  Future<void> deleteUser(String idKeycloak);
}