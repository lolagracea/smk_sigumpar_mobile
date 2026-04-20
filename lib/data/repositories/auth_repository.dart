import '../remote/auth_api.dart';

class AuthRepository {
  AuthRepository(this._api);
  final AuthApi _api;

  Future<void> login() => _api.login();
}
