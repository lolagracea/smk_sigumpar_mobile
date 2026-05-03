import 'package:flutter/material.dart';
import 'package:smk_sigumpar/data/models/user_model.dart';
import 'package:smk_sigumpar/data/repositories/auth_repository.dart';
import 'package:smk_sigumpar/core/utils/secure_storage.dart';
import 'package:smk_sigumpar/core/utils/token_helper.dart';
import 'package:smk_sigumpar/core/utils/role_helper.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// ─────────────────────────────────────────────────────────────
/// AuthProvider — state management untuk autentikasi
///
/// PERUBAHAN dari versi lama:
/// - Menyimpan UserModel yang kini punya List<String> roles
/// - Expose `roles` getter (semua role user)
/// - Expose `primaryRole` getter
/// - `hasRole(String)` method untuk RBAC check
/// - `hasAnyRole(List<String>)` method untuk multi-role check
/// ─────────────────────────────────────────────────────────────
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
        _secureStorage = secureStorage {
    _checkAuth();
  }

  // ─── Getters ─────────────────────────────────────────────
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Semua role user (multi-role)
  List<String> get roles => _user?.roles ?? [];

  /// Role utama user
  String get primaryRole => _user?.primaryRole ?? '';

  /// Cek apakah user punya role tertentu
  /// Gunakan ini di widget untuk RBAC check
  ///
  /// Contoh: `authProvider.hasRole(AppRoles.pramuka)`
  bool hasRole(String role) => _user?.hasRole(role) ?? false;

  /// Cek apakah user punya salah satu dari daftar role
  ///
  /// Contoh: `authProvider.hasAnyRole([AppRoles.pramuka, AppRoles.teacher])`
  bool hasAnyRole(List<String> checkRoles) =>
      _user?.hasAnyRole(checkRoles) ?? false;

  // ─── Check existing auth ──────────────────────────────────
  Future<void> _checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final hasToken = await _secureStorage.hasToken();
      if (hasToken) {
        final token = await _secureStorage.getAccessToken();
        if (token != null && !TokenHelper.isExpired(token)) {
          _user = await _authRepository.getProfile();
          _status = AuthStatus.authenticated;

          debugPrint('✅ Auth restored: ${_user?.name}, roles: ${_user?.roles}');
        } else {
          await _secureStorage.clearAll();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('❌ _checkAuth error: $e');
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // ─── Login ───────────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authRepository.login(
        username: username,
        password: password,
      );

      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;

      if (accessToken == null) {
        _errorMessage = 'Token tidak ditemukan dalam response.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }

      await _secureStorage.saveAccessToken(accessToken);
      if (refreshToken != null) {
        await _secureStorage.saveRefreshToken(refreshToken);
      }

      // ✅ getProfile sekarang return UserModel dengan multi-role
      _user = await _authRepository.getProfile();

      debugPrint('✅ Login success: ${_user?.name}');
      debugPrint('✅ Roles: ${_user?.roles}');
      debugPrint('✅ Primary: ${_user?.primaryRole}');

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('NetworkExceptions: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ──────────────────────────────────────────────
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      await _authRepository.logout(refreshToken);
    } catch (e) {
      debugPrint('Server logout failed (non-critical): $e');
    }

    await _secureStorage.clearAll();

    _user = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ─── Refresh profile ─────────────────────────────────────
  Future<void> refreshProfile() async {
    try {
      _user = await _authRepository.getProfile();
      notifyListeners();
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}