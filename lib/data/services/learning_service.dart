import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/wakil_kepsek_model.dart';

class LearningService {
  LearningService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _headers(String token) => <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  // ── Perangkat Guru ────────────────────────────────────────────────────────

  Future<List<GuruPerangkatModel>> getDaftarGuruPerangkat(String token) async {
    final res = await _client.get(
      _uri(ApiConstants.wakilPerangkatGuru),
      headers: _headers(token),
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data
        .map((e) => GuruPerangkatModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GuruPerangkatDetailModel> getPerangkatByGuru(
      String token, int guruId) async {
    final res = await _client.get(
      _uri('${ApiConstants.wakilPerangkatGuru}/$guruId'),
      headers: _headers(token),
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final guru = GuruInfoModel.fromJson(body['guru'] as Map<String, dynamic>);
    final data = (body['data'] as List<dynamic>)
        .map((e) => WakilPerangkatModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return GuruPerangkatDetailModel(guru: guru, perangkatList: data);
  }

  Future<WakilPerangkatModel> createPerangkat(
      String token, Map<String, dynamic> payload) async {
    final res = await _client.post(
      _uri(ApiConstants.wakilPerangkat),
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return WakilPerangkatModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<WakilPerangkatModel> updatePerangkat(
      String token, int id, Map<String, dynamic> payload) async {
    final res = await _client.put(
      _uri('${ApiConstants.wakilPerangkat}/$id'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return WakilPerangkatModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deletePerangkat(String token, int id) async {
    final res = await _client.delete(
      _uri('${ApiConstants.wakilPerangkat}/$id'),
      headers: _headers(token),
    );
    _checkStatus(res);
  }

  // ── Jadwal ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getJadwalMonitoring(
    String token, {
    String? hari,
    String? kelasId,
    String? guruId,
    String? mapel,
  }) async {
    final params = <String, String>{};
    if (hari != null) params['hari'] = hari;
    if (kelasId != null) params['kelas_id'] = kelasId;
    if (guruId != null) params['guru_id'] = guruId;
    if (mapel != null) params['mapel'] = mapel;

    final res = await _client.get(
      _uri(ApiConstants.wakilJadwal, params),
      headers: _headers(token),
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>)
        .map((e) => JadwalModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return <String, dynamic>{
      'total': body['total'] as int? ?? data.length,
      'bentrok': body['bentrok'] as int? ?? 0,
      'data': data,
    };
  }

  Future<List<RekapHariModel>> getRekapJadwalPerHari(String token) async {
    final res = await _client.get(
      _uri(ApiConstants.wakilJadwalRekapHari),
      headers: _headers(token),
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data
        .map((e) => RekapHariModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Laporan ───────────────────────────────────────────────────────────────

  Future<LaporanRingkasModel> getLaporanRingkas(String token) async {
    final res = await _client.get(
      _uri(ApiConstants.wakilLaporanRingkas),
      headers: _headers(token),
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return LaporanRingkasModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message = 'Gagal: HTTP ${res.statusCode}';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        message = body['error']?.toString() ??
            body['message']?.toString() ??
            message;
      } catch (_) {}
      throw Exception(message);
    }
  }
}
