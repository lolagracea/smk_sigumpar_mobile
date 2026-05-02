import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/secure_storage.dart';
import '../../core/utils/token_helper.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthService implements AuthRepository {
  final DioClient _dioClient;
  final SecureStorage _secureStorage;

  AuthService({
    required DioClient dioClient,
    required SecureStorage secureStorage,
  })  : _dioClient = dioClient,
        _secureStorage = secureStorage;

  // ─── LOGIN ───────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.keycloakTokenUrl,
      data: {
        'client_id': ApiEndpoints.keycloakClientId,
        'grant_type': 'password',
        'username': username,
        'password': password,
        'scope': 'openid profile email',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── LOGOUT ──────────────────────────────────────────────
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

  // ─── GET PROFILE (FIXED ROLE DETECTION) ──────────────────
  @override
  Future<UserModel> getProfile() async {
    // 1. Get user info dari Keycloak userinfo endpoint
    final response = await _dioClient.get(ApiEndpoints.keycloakUserInfoUrl);
    final data = response.data;

    // 2. Extract role dari JWT access token
    // (Keycloak userinfo TIDAK return roles by default)
    final accessToken = await _secureStorage.getAccessToken();
    String role = 'user';

    if (accessToken != null) {
      // 🐛 DEBUG: Print untuk verifikasi (HAPUS setelah confirmed working)
      if (kDebugMode) {
        final payload = TokenHelper.decodePayload(accessToken);
        print('🔍 JWT realm_access: ${payload?['realm_access']}');

        final roles = TokenHelper.getRoles(accessToken);
        print('🔍 All roles found: $roles');
      }

      role = TokenHelper.getPrimaryRole(accessToken);

      if (kDebugMode) {
        print('🔍 Primary role selected: $role');
      }
    }

    return UserModel(
      id: data['sub'] ?? '',
      username: data['preferred_username'] ?? '',
      name: data['name'] ?? data['preferred_username'] ?? '',
      email: data['email'] ?? '',
      role: role, // ✅ Real role dari JWT
    );
  }

  // ─── UPDATE PROFILE (Backend tidak punya endpoint) ───────
  @override
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    throw UnimplementedError(
      'Update profile belum tersedia. Silakan update via Keycloak Account Console.',
    );
  }

  // ─── CHANGE PASSWORD (Backend tidak punya endpoint) ──────
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    throw UnimplementedError(
      'Ganti password belum tersedia. Silakan ganti via Keycloak Account Console.',
    );
  }

  // ─── REFRESH TOKEN ───────────────────────────────────────
  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.keycloakTokenUrl,
      data: {
        'client_id': ApiEndpoints.keycloakClientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'scope': 'openid profile email',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data as Map<String, dynamic>;
  }
}