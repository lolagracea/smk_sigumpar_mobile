import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthService implements AuthRepository {
  final DioClient _dioClient;

  // Sesuaikan dengan Client ID Keycloak di docker-compose Anda
  final String _keycloakClientId = 'smk-sigumpar';

  // 1. URL untuk proses Login dan Refresh Token
  final String _keycloakTokenUrl = kIsWeb
      ? 'http://localhost:8080/realms/smk-sigumpar/protocol/openid-connect/token'
      : 'http://10.0.2.2:8080/realms/smk-sigumpar/protocol/openid-connect/token';

  // 2. URL untuk mengambil Data Profil
  final String _keycloakUserInfoUrl = kIsWeb
      ? 'http://localhost:8080/realms/smk-sigumpar/protocol/openid-connect/userinfo'
      : 'http://10.0.2.2:8080/realms/smk-sigumpar/protocol/openid-connect/userinfo';

  AuthService({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    // Fungsi ini tetap menggunakan .dio.post (tanpa interceptor) karena belum punya token
    final response = await _dioClient.dio.post(
      _keycloakTokenUrl,
      data: {
        'client_id': _keycloakClientId,
        'grant_type': 'password',
        'username': username,
        'password': password,
        'scope': 'openid profile email', // 👈 Penambahan scope untuk OpenID Connect
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data as Map<String, dynamic>;
  }



// Di auth_service.dart implementation:
  @override
  Future<void> logout(String? refreshToken) async {
    if (refreshToken == null) return;

    try {
      await _dioClient.dio.post(
        ApiEndpoints.keycloakLogoutUrl,
        data: {
          'client_id': ApiEndpoints.keycloakClientId,
          'refresh_token': refreshToken,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Keycloak logout failed: $e');
    }
  }

  @override
  Future<UserModel> getProfile() async {
    // LANGSUNG tembak menggunakan _dioClient.get (TIDAK PAKAI .dio.get)
    // Interceptor di dio_client.dart akan OTOMATIS menyematkan Bearer Token-nya
    final response = await _dioClient.get(_keycloakUserInfoUrl);

    // Keycloak akan membalas dengan data profil
    final data = response.data;

    return UserModel(
      id: data['sub'],
      username: data['preferred_username'],
      name: data['name'] ?? data['preferred_username'],
      email: data['email'] ?? '',
      role: 'user',
    );
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
        'scope': 'openid profile email', // 👈 Penambahan scope untuk OpenID Connect
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data as Map<String, dynamic>;
  }
}