class KeycloakOidcService {
  Future<String?> login() async {
    // TODO: Integrasikan flutter_appauth / oidc_client sesuai flow Keycloak
    return null;
  }

  Future<void> logout() async {
    // TODO: revoke token / clear session
  }

  Future<String?> getAccessToken() async {
    // TODO: ambil token dari secure storage
    return null;
  }

  Future<String?> refreshToken() async {
    // TODO: refresh token ke Keycloak
    return null;
  }
}
