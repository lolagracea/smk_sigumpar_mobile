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

  // ─── GET PROFILE — MULTI-ROLE SUPPORT ────────────────────
  @override
  Future<UserModel> getProfile() async {
    // 1. Ambil userinfo dari Keycloak
    final response = await _dioClient.get(ApiEndpoints.keycloakUserInfoUrl);
    final data = response.data;

    // 2. Extract SEMUA roles dari JWT access token
    final accessToken = await _secureStorage.getAccessToken();

    List<String> allRoles = [];
    String primaryRole = 'user';

    if (accessToken != null) {
      // ✅ Ambil SEMUA roles (bukan hanya primary)
      allRoles = TokenHelper.getRoles(accessToken);
      primaryRole = TokenHelper.getPrimaryRole(accessToken);

      if (kDebugMode) {
        final payload = TokenHelper.decodePayload(accessToken);
        debugPrint('🔍 JWT realm_access: ${payload?['realm_access']}');
        debugPrint('🔍 All roles found: $allRoles');
        debugPrint('🔍 Primary role selected: $primaryRole');
      }
    }

    // Fallback kalau roles kosong
    if (allRoles.isEmpty && primaryRole != 'user') {
      allRoles = [primaryRole];
    } else if (allRoles.isEmpty) {
      allRoles = ['user'];
    }

    // Pastikan primaryRole ada di allRoles
    if (!allRoles.contains(primaryRole)) {
      allRoles = [primaryRole, ...allRoles];
    }

    if (kDebugMode) {
      debugPrint('✅ UserModel roles: $allRoles, primary: $primaryRole');
    }

    return UserModel(
      id: data['sub'] ?? '',
      username: data['preferred_username'] ?? '',
      name: data['name'] ?? data['preferred_username'] ?? '',
      email: data['email'] ?? '',
      roles: allRoles,           // ✅ Multi-role
      primaryRole: primaryRole,  // ✅ Primary role
    );
  }

  // ─── UPDATE PROFILE ──────────────────────────────────────
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

  // ─── CHANGE PASSWORD ─────────────────────────────────────
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