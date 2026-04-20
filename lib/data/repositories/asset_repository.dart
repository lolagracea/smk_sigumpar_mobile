import '../remote/asset_api.dart';

class AssetRepository {
  AssetRepository(this._api);
  final AssetApi _api;

  Future<void> ping() => _api.getRingkasan();
}
