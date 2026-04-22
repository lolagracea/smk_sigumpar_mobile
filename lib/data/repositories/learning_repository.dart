import '../models/wakil_kepsek_model.dart';
import '../services/learning_service.dart';

class LearningRepository {
  LearningRepository({required LearningService service})
      : _service = service;

  final LearningService _service;

  // ── Perangkat ──────────────────────────────────────────────────────────────

  Future<List<GuruPerangkatModel>> getDaftarGuruPerangkat(String token) =>
      _service.getDaftarGuruPerangkat(token);

  Future<GuruPerangkatDetailModel> getPerangkatByGuru(
          String token, int guruId) =>
      _service.getPerangkatByGuru(token, guruId);

  Future<WakilPerangkatModel> createPerangkat(
          String token, Map<String, dynamic> payload) =>
      _service.createPerangkat(token, payload);

  Future<WakilPerangkatModel> updatePerangkat(
          String token, int id, Map<String, dynamic> payload) =>
      _service.updatePerangkat(token, id, payload);

  Future<void> deletePerangkat(String token, int id) =>
      _service.deletePerangkat(token, id);

  // ── Jadwal ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getJadwalMonitoring(
    String token, {
    String? hari,
    String? kelasId,
    String? guruId,
    String? mapel,
  }) =>
      _service.getJadwalMonitoring(
        token,
        hari: hari,
        kelasId: kelasId,
        guruId: guruId,
        mapel: mapel,
      );

  Future<List<RekapHariModel>> getRekapJadwalPerHari(String token) =>
      _service.getRekapJadwalPerHari(token);

  // ── Laporan ───────────────────────────────────────────────────────────────

  Future<LaporanRingkasModel> getLaporanRingkas(String token) =>
      _service.getLaporanRingkas(token);
}
