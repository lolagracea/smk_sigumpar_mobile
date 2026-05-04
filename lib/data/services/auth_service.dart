import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/secure_storage.dart';
import '../../core/utils/token_helper.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'package:flutter/material.dart';

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
    final response = await _dioClient.get(ApiEndpoints.keycloakUserInfoUrl);
    final data = response.data;

    final accessToken = await _secureStorage.getAccessToken();

    String primaryRole = 'user';
    List<String> roles = [];

    if (accessToken != null) {
      roles = TokenHelper.getRoles(accessToken);
      primaryRole = TokenHelper.getPrimaryRole(accessToken);

      debugPrint('✅ MOBILE PRIMARY ROLE: $primaryRole');
      debugPrint('✅ MOBILE ALL ROLES: $roles');
    }

    return UserModel(
      id: data['sub']?.toString() ?? '',
      username: data['preferred_username']?.toString() ?? '',
      name: data['name']?.toString() ??
          data['preferred_username']?.toString() ??
          '',
      email: data['email']?.toString() ?? '',
      role: primaryRole,
      roles: roles,
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