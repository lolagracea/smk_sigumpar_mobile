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
        _secureStorage = secureStorage {
    _checkAuth();
  }

  // ─── Getters ─────────────────────────────────────────────
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

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
        } else {
          await _secureStorage.clearAll();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
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

      _user = await _authRepository.getProfile();
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
    try {
      await _authRepository.logout();
    } catch (_) {}
    await _secureStorage.clearAll();
    _user = null;
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
