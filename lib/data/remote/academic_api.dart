import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class AcademicApi {
  AcademicApi(this._client);
  final ApiClient _client;

  Future<void> getKelas() async => _client.get('${ApiEndpoints.academic}/kelas');
  Future<void> getSiswa() async => _client.get('${ApiEndpoints.academic}/siswa');
  Future<void> getPengumuman() async => _client.get('${ApiEndpoints.academic}/pengumuman');
  Future<void> getArsipSurat() async => _client.get('${ApiEndpoints.academic}/arsip-surat');
}
