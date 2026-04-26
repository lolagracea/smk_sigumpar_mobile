import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/utils/secure_storage.dart';
import '../../../core/utils/token_helper.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SecureStorage _secureStorage;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthProvider({
    required AuthRepository authRepository,
    required SecureStorage secureStorage,
  })  : _authRepository = authRepository,
        _secureStorage = secureStorage;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // ─── FUNGSI DECODE JWT LOKAL ──────────────────────────────
  UserModel _decodeUserFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Format token tidak sah');

      String payload = parts[1];
      String normalized = base64Url.normalize(payload);
      String decodedPayload = utf8.decode(base64Url.decode(normalized));
      Map<String, dynamic> data = json.decode(decodedPayload);

      List<String> userRoles = ['user'];
      if (data['realm_access'] != null && data['realm_access']['roles'] != null) {
        userRoles = List<String>.from(data['realm_access']['roles']);
      }

      return UserModel(
        id: data['sub']?.toString() ?? '',
        username: data['preferred_username']?.toString() ?? '',
        name: data['name']?.toString() ?? data['preferred_username']?.toString() ?? 'Pengguna',
        email: data['email']?.toString() ?? '',
        role: userRoles.isNotEmpty ? userRoles.first : 'user',
      );
    } catch (e) {
      print('=== RALAT DECODE JWT ===: $e');
      throw Exception('Gagal membaca maklumat profil dari token: $e');
    }
  }

  // ─── SEMAK STATUS LOGIN (Digunakan oleh main.dart) ────────
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final hasToken = await _secureStorage.hasToken();
      if (hasToken) {
        final token = await _secureStorage.getAccessToken();
        if (token != null && !TokenHelper.isExpired(token)) {
          _user = _decodeUserFromToken(token);
          _status = AuthStatus.authenticated;
        } else {
          await _secureStorage.clearAll();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      print('=== RALAT CHECK AUTH ===: $e');
      await _secureStorage.clearAll();
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // ─── REFRESH PROFIL (Digunakan oleh ProfileScreen) ─────────
  Future<void> refreshProfile() async {
    // Memandangkan kita menggunakan Decode JWT, 'refresh' bermaksud
    // kita cuba menyahkod semula token yang ada di dalam storan.
    await checkAuthStatus();
  }

  // ─── PROSES LOGIN ──────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final tokenData = await _authRepository.login(
        username: username,
        password: password,
      );

      final accessToken = tokenData['access_token'] as String?;
      final refreshToken = tokenData['refresh_token'] as String?;

      if (accessToken == null) {
        throw Exception('Token tidak ditemui dalam respons pelayan.');
      }

      _user = _decodeUserFromToken(accessToken);

      await _secureStorage.saveAccessToken(accessToken);
      if (refreshToken != null) {
        await _secureStorage.saveRefreshToken(refreshToken);
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;

    } catch (e) {
      print('=== RALAT LOGIN ===: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ─── PROSES LOGOUT ─────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {}
    await _secureStorage.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}