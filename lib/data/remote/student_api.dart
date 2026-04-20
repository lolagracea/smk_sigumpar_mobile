import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class StudentApi {
  StudentApi(this._client);
  final ApiClient _client;

  Future<void> getRingkasan() async => _client.get(ApiEndpoints.students);
}
