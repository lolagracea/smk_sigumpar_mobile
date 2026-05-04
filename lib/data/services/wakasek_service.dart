import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/wakasek_models.dart';

/// Base URL learning-service — sesuaikan dengan environment-mu
const String _learningBase = 'http://10.0.2.2:3004/api/learning';

/// Header dummy token (ganti dengan token Keycloak saat auth sudah nyata)
Map<String, String> _headers(String token) => {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
};

class WakasekService {
  // ─── PERANGKAT PEMBELAJARAN ────────────────────────────────────

  Future<List<PerangkatModel>> getPerangkat({
    String? statusReview,
    String? jenisDokumen,
    String? search,
    required String token,
  }) async {
    final params = <String, String>{};
    if (statusReview != null) params['status_review'] = statusReview;
    if (jenisDokumen != null) params['jenis_dokumen'] = jenisDokumen;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$_learningBase/perangkat')
        .replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(uri, headers: _headers(token));
    _throwIfError(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => PerangkatModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> reviewPerangkat({
    required int id,
    required String status, // 'disetujui' | 'revisi' | 'ditolak'
    String? catatan,
    required String token,
  }) async {
    final uri = Uri.parse('$_learningBase/perangkat/$id/review-wakasek');
    final response = await http.put(
      uri,
      headers: _headers(token),
      body: jsonEncode({'status': status, 'catatan': catatan}),
    );
    _throwIfError(response);
  }

  Future<List<RiwayatReviewModel>> getRiwayatReview({
    required int id,
    required String token,
  }) async {
    final uri = Uri.parse('$_learningBase/perangkat/$id/riwayat-review');
    final response = await http.get(uri, headers: _headers(token));
    _throwIfError(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => RiwayatReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── EVALUASI GURU ────────────────────────────────────────────

  Future<List<EvaluasiGuruModel>> getEvaluasiGuru({
    required String token,
  }) async {
    final uri = Uri.parse('$_learningBase/evaluasi-guru');
    final response = await http.get(uri, headers: _headers(token));
    _throwIfError(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => EvaluasiGuruModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GuruMapelModel>> getGuruMapelList({
    required String token,
  }) async {
    final uri = Uri.parse('$_learningBase/evaluasi-guru/guru-mapel');
    final response = await http.get(uri, headers: _headers(token));
    _throwIfError(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => GuruMapelModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createEvaluasiGuru({
    required String guruId,
    required String namaGuru,
    String? mapel,
    String? semester,
    int? skor,
    String? predikat,
    String? catatan,
    required String token,
  }) async {
    final uri = Uri.parse('$_learningBase/evaluasi-guru');
    final response = await http.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'guru_id': guruId,
        'nama_guru': namaGuru,
        if (mapel != null) 'mapel': mapel,
        if (semester != null) 'semester': semester,
        if (skor != null) 'skor': skor,
        if (predikat != null) 'predikat': predikat,
        if (catatan != null) 'catatan': catatan,
      }),
    );
    _throwIfError(response);
  }

  // ─── CATATAN MENGAJAR ──────────────────────────────────────────

  Future<List<CatatanMengajarModel>> getCatatanMengajar({
    String? guruId,
    String? tanggal,
    required String token,
  }) async {
    final params = <String, String>{};
    if (guruId != null) params['guru_id'] = guruId;
    if (tanggal != null) params['tanggal'] = tanggal;

    final uri = Uri.parse('$_learningBase/catatan-mengajar')
        .replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(uri, headers: _headers(token));
    _throwIfError(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => CatatanMengajarModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── HELPER ────────────────────────────────────────────────────

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message =
          body['message'] as String? ?? 'Terjadi kesalahan pada server';
      throw Exception(message);
    }
  }
}