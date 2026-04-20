import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  Future<void> login() async {
    await _client.get(ApiEndpoints.auth);
  }
}
