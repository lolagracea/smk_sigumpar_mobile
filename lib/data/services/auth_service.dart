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

      // 1. Decode JWT Access Token (Seperti biasa)
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Format token tidak sah');

      String payload = parts[1];
      String normalized = base64Url.normalize(payload);
      String decodedPayload = utf8.decode(base64Url.decode(normalized));
      Map<String, dynamic> tokenData = json.decode(decodedPayload);

      // 2. MINTA DATA LENGKAP KE ENDPOINT USERINFO KEYCLOAK (Cara Web)
      // Gunakan URL dasar Keycloak Anda dengan memotong bagian '/token'
      final String userInfoUrl = _keycloakTokenUrl.replaceAll('/token', '/userinfo');

      Map<String, dynamic> userInfoData = {};
      try {
        final userInfoResponse = await _dioClient.dio.get(
          userInfoUrl,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        userInfoData = userInfoResponse.data as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Gagal mengambil userinfo, menggunakan data token lokal: $e');
      }

      // 3. GABUNGKAN DATA (Token Lokal + Data UserInfo)
      final Map<String, dynamic> combinedData = {...tokenData, ...userInfoData};

      // 4. EKSTRAKSI ROLE SECARA AGRESIF (Mencari di semua "laci" Keycloak)
      Set<String> extractedRoles = {}; // Pakai Set agar tidak ada role duplikat

      // Laci A: realm_access (Bawaan Keycloak)
      if (combinedData['realm_access'] != null && combinedData['realm_access']['roles'] != null) {
        extractedRoles.addAll(List<String>.from(combinedData['realm_access']['roles']));
      }

      // Laci B: resource_access (Client Roles - Biasanya role custom sembunyi di sini)
      if (combinedData['resource_access'] != null) {
        combinedData['resource_access'].forEach((key, value) {
          if (value['roles'] != null) {
            extractedRoles.addAll(List<String>.from(value['roles']));
          }
        });
      }

      // Laci C: roles dari UserInfo atau Array langsung
      if (combinedData['roles'] != null && combinedData['roles'] is List) {
        extractedRoles.addAll(List<String>.from(combinedData['roles']));
      }

      // Jika role penting (seperti tata-usaha) ditemukan dalam string biasa
      if (combinedData['role'] != null && combinedData['role'] is String) {
        extractedRoles.add(combinedData['role'].toString());
      }

      // 5. KEMBALIKAN MODEL USER
      return UserModel(
        id: combinedData['sub']?.toString() ?? '',
        username: combinedData['preferred_username']?.toString() ?? '',
        name: combinedData['name']?.toString() ?? combinedData['preferred_username']?.toString() ?? 'Pengguna',
        email: combinedData['email']?.toString() ?? '',
        // Gabungkan semua role menjadi satu string (contoh: "default-roles-smk-sigumpar, tata-usaha")
        role: extractedRoles.isNotEmpty ? extractedRoles.join(', ') : 'user',
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
        'scope': 'openid profile email offline_access',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data as Map<String, dynamic>;
  }
}