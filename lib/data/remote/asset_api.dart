import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class AssetApi {
  AssetApi(this._client);
  final ApiClient _client;

  Future<void> getRingkasan() async => _client.get(ApiEndpoints.asset);
}
