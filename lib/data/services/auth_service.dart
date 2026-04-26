import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/secure_storage.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthService implements AuthRepository {
  final DioClient _dioClient;
  final SecureStorage _secureStorage;
  final String _keycloakClientId = 'smk-sigumpar';

  final String _keycloakTokenUrl = kIsWeb
      ? 'http://localhost:8080/realms/smk-sigumpar/protocol/openid-connect/token'
      : 'http://10.0.2.2:8080/realms/smk-sigumpar/protocol/openid-connect/token';

  AuthService({
    required DioClient dioClient,
    required SecureStorage secureStorage,
  })  : _dioClient = dioClient,
        _secureStorage = secureStorage;

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _dioClient.dio.post(
      _keycloakTokenUrl,
      data: {
        'client_id': _keycloakClientId,
        'grant_type': 'password',
        'username': username,
        'password': password,
        // 👇 PERUBAHAN UTAMA 1: Tambahkan offline_access di sini
        // Ini memberitahu Keycloak untuk memberikan token sesi jangka panjang untuk Mobile
        'scope': 'openid profile email offline_access',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> logout() async {
    try {
      await _dioClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Abaikan ralat API, biarkan proses berlanjut agar token di HP tetap terhapus
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesi telah tamat. Sila log masuk semula.');
      }

      // Decode JWT
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Format token tidak sah');

      String payload = parts[1];
      String normalized = base64Url.normalize(payload);
      String decodedPayload = utf8.decode(base64Url.decode(normalized));
      Map<String, dynamic> data = json.decode(decodedPayload);

      // Ekstrak peranan (roles) dari Keycloak
      List<String> userRoles = ['user'];
      if (data['realm_access'] != null && data['realm_access']['roles'] != null) {
        userRoles = List<String>.from(data['realm_access']['roles']);
      }

      // 👇 KEMAS KINI DI SINI: Padankan tepat dengan UserModel anda
      return UserModel(
        id: data['sub']?.toString() ?? '',
        username: data['preferred_username']?.toString() ?? '',
        name: data['name']?.toString() ?? data['preferred_username']?.toString() ?? 'Pengguna',
        email: data['email']?.toString() ?? '', // Ditambah kembali
        role: userRoles.isNotEmpty ? userRoles.first : 'user', // Ditukar dari 'roles' kepada 'role'
      );

    } catch (e) {
      throw Exception('Gagal memuat data profil: $e');
    }
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;
    await _dioClient.put('${ApiEndpoints.profile}/update', data: data);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dioClient.post(
      '${ApiEndpoints.profile}/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dioClient.dio.post(
      _keycloakTokenUrl,
      data: {
        'client_id': _keycloakClientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        // 👇 PERUBAHAN UTAMA 2: Pastikan offline_access juga ada semasa refresh token
        'scope': 'openid profile email offline_access',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data as Map<String, dynamic>;
  }
}