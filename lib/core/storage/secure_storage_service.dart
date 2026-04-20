class SecureStorageService {
  String? _accessToken;
  String? _refreshToken;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  Future<String?> getAccessToken() async => _accessToken;
  Future<String?> getRefreshToken() async => _refreshToken;

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
