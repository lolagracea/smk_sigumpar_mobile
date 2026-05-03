import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  AuthRepository({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(),
        _secureStorage = storage ?? const FlutterSecureStorage();

  // ── Storage helpers (web pakai SharedPrefs, mobile pakai SecureStorage) ──
  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  Future<void> _deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } else {
      await _secureStorage.deleteAll();
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<UserModel> login(String username, String password) async {
    try {
      print('=== LOGIN: mencoba ke Keycloak...');
      print('=== URL: ${AppConstants.keycloakUrl}/realms/${AppConstants.keycloakRealm}/protocol/openid-connect/token');

      final response = await _dio.post(
        '${AppConstants.keycloakUrl}/realms/${AppConstants.keycloakRealm}/protocol/openid-connect/token',
        data: {
          'client_id': AppConstants.keycloakClientId,
          'username': username,
          'password': password,
          'grant_type': 'password',
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      print('=== LOGIN: berhasil dapat token!');

      final token = response.data['access_token']?.toString() ?? '';
      final refreshToken = response.data['refresh_token']?.toString() ?? '';

      final payload = _decodeJwt(token);
      print('=== JWT PAYLOAD: $payload');

      final user = UserModel.fromJson({
        ...payload,
        'access_token': token,
        'refresh_token': refreshToken,
      });

      print('=== USER: name=${user.name}, role=${user.role}');

      await _write(AppConstants.tokenKey, token);
      await _write(AppConstants.refreshTokenKey, refreshToken);
      await _write(AppConstants.userDataKey, jsonEncode(user.toJson()));

      print('=== LOGIN: data tersimpan, return user');
      return user;
    } on DioException catch (e) {
      print('=== LOGIN ERROR: ${e.response?.statusCode}');
      print('=== LOGIN ERROR DATA: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Username atau password salah');
      }
      throw Exception(e.error?.toString() ?? 'Login gagal. Periksa koneksi internet.');
    }
  }

  // ── Get Stored User ────────────────────────────────────────────────────────
  Future<UserModel?> getStoredUser() async {
    try {
      final userData = await _read(AppConstants.userDataKey);
      final token = await _read(AppConstants.tokenKey);

      print('=== GET STORED USER: userData=${userData != null}, token=${token != null}');

      if (userData == null || token == null) return null;

      final payload = _decodeJwt(token);
      final exp = payload['exp'] as int?;
      if (exp != null) {
        final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (expDate.isBefore(DateTime.now())) {
          print('=== TOKEN EXPIRED, mencoba refresh...');
          final refreshed = await _refreshToken();
          if (!refreshed) {
            await _deleteAll();
            return null;
          }
        }
      }

      return UserModel.fromJson(jsonDecode(userData));
    } catch (e) {
      print('=== GET STORED USER ERROR: $e');
      return null;
    }
  }

  // ── Refresh Token ──────────────────────────────────────────────────────────
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _read(AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '${AppConstants.keycloakUrl}/realms/${AppConstants.keycloakRealm}/protocol/openid-connect/token',
        data: {
          'client_id': AppConstants.keycloakClientId,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      await _write(AppConstants.tokenKey, response.data['access_token'].toString());
      await _write(AppConstants.refreshTokenKey, response.data['refresh_token'].toString());
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final refreshToken = await _read(AppConstants.refreshTokenKey);
      if (refreshToken != null) {
        await _dio.post(
          '${AppConstants.keycloakUrl}/realms/${AppConstants.keycloakRealm}/protocol/openid-connect/logout',
          data: {
            'client_id': AppConstants.keycloakClientId,
            'refresh_token': refreshToken,
          },
          options: Options(contentType: 'application/x-www-form-urlencoded'),
        );
      }
    } catch (_) {}
    await _deleteAll();
  }

  // ── Decode JWT ─────────────────────────────────────────────────────────────
  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      String payload = parts[1];
      while (payload.length % 4 != 0) payload += '=';
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      print('=== DECODE JWT ERROR: $e');
      return {};
    }
  }
}