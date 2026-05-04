import '../models/wakasek_models.dart';
import '../services/wakasek_service.dart';

class WakasekRepository {
  WakasekRepository({WakasekService? service})
      : _service = service ?? WakasekService();

  final WakasekService _service;

  // ─── PERANGKAT ──────────────────────────────────────────────

  Future<List<PerangkatModel>> getPerangkat({
    String? statusReview,
    String? jenisDokumen,
    String? search,
    required String token,
  }) =>
      _service.getPerangkat(
        statusReview: statusReview,
        jenisDokumen: jenisDokumen,
        search: search,
        token: token,
      );

  Future<void> reviewPerangkat({
    required int id,
    required String status,
    String? catatan,
    required String token,
  }) =>
      _service.reviewPerangkat(
        id: id,
        status: status,
        catatan: catatan,
        token: token,
      );

  Future<List<RiwayatReviewModel>> getRiwayatReview({
    required int id,
    required String token,
  }) =>
      _service.getRiwayatReview(id: id, token: token);

  // ─── EVALUASI GURU ─────────────────────────────────────────

  Future<List<EvaluasiGuruModel>> getEvaluasiGuru({
    required String token,
  }) =>
      _service.getEvaluasiGuru(token: token);

  Future<List<GuruMapelModel>> getGuruMapelList({
    required String token,
  }) =>
      _service.getGuruMapelList(token: token);

  Future<void> createEvaluasiGuru({
    required String guruId,
    required String namaGuru,
    String? mapel,
    String? semester,
    int? skor,
    String? predikat,
    String? catatan,
    required String token,
  }) =>
      _service.createEvaluasiGuru(
        guruId: guruId,
        namaGuru: namaGuru,
        mapel: mapel,
        semester: semester,
        skor: skor,
        predikat: predikat,
        catatan: catatan,
        token: token,
      );

  // ─── CATATAN MENGAJAR ───────────────────────────────────────

  Future<List<CatatanMengajarModel>> getCatatanMengajar({
    String? guruId,
    String? tanggal,
    required String token,
  }) =>
      _service.getCatatanMengajar(
        guruId: guruId,
        tanggal: tanggal,
        token: token,
      );
}