import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';

// ─── Program Kerja Model ─────────────────────────────────────
class ProgramKerjaModel {
  final int id;
  final String namaProgram;
  final String bidang;
  final String tanggalMulai;
  final String? tanggalSelesai;
  final String? penanggungJawab;
  final String status;
  final String? deskripsi;

  ProgramKerjaModel({
    required this.id,
    required this.namaProgram,
    required this.bidang,
    required this.tanggalMulai,
    this.tanggalSelesai,
    this.penanggungJawab,
    required this.status,
    this.deskripsi,
  });

  factory ProgramKerjaModel.fromJson(Map<String, dynamic> json) {
    return ProgramKerjaModel(
      id: json['id'] ?? 0,
      namaProgram: json['nama_program'] ?? '',
      bidang: json['bidang'] ?? 'Kurikulum',
      tanggalMulai: json['tanggal_mulai'] ?? '',
      tanggalSelesai: json['tanggal_selesai'],
      penanggungJawab: json['penanggung_jawab'],
      status: json['status'] ?? 'belum_mulai',
      deskripsi: json['deskripsi'],
    );
  }

  Map<String, dynamic> toJson() => {
        'nama_program': namaProgram,
        'bidang': bidang,
        'tanggal_mulai': tanggalMulai,
        if (tanggalSelesai != null) 'tanggal_selesai': tanggalSelesai,
        if (penanggungJawab != null) 'penanggung_jawab': penanggungJawab,
        'status': status,
        if (deskripsi != null) 'deskripsi': deskripsi,
      };
}

// ─── Supervisi Model ─────────────────────────────────────────
class SupervisiModel {
  final int id;
  final int guruId;
  final String? namaGuru;
  final String tanggal;
  final String? kelas;
  final String? mataPelajaran;
  final String? aspekPenilaian;
  final double? nilai;
  final String? catatan;
  final String? rekomendasi;

  SupervisiModel({
    required this.id,
    required this.guruId,
    this.namaGuru,
    required this.tanggal,
    this.kelas,
    this.mataPelajaran,
    this.aspekPenilaian,
    this.nilai,
    this.catatan,
    this.rekomendasi,
  });

  factory SupervisiModel.fromJson(Map<String, dynamic> json) {
    return SupervisiModel(
      id: json['id'] ?? 0,
      guruId: json['guru_id'] ?? 0,
      namaGuru: json['nama_guru'],
      tanggal: (json['tanggal'] ?? '').toString().split('T').first,
      kelas: json['kelas'],
      mataPelajaran: json['mata_pelajaran'],
      aspekPenilaian: json['aspek_penilaian'],
      nilai: json['nilai'] != null ? double.tryParse(json['nilai'].toString()) : null,
      catatan: json['catatan'],
      rekomendasi: json['rekomendasi'],
    );
  }

  Map<String, dynamic> toJson() => {
        'guru_id': guruId,
        'tanggal': tanggal,
        if (kelas != null) 'kelas': kelas,
        if (mataPelajaran != null) 'mata_pelajaran': mataPelajaran,
        if (aspekPenilaian != null) 'aspek_penilaian': aspekPenilaian,
        if (nilai != null) 'nilai': nilai,
        if (catatan != null) 'catatan': catatan,
        if (rekomendasi != null) 'rekomendasi': rekomendasi,
      };
}

// ─── Provider ────────────────────────────────────────────────
class WakilKepsekProvider extends ChangeNotifier {
  final DioClient _dioClient;

  WakilKepsekProvider({required DioClient dioClient}) : _dioClient = dioClient;

  // ── Program Kerja state ──
  List<ProgramKerjaModel> programKerjaList = [];
  bool isLoadingProgramKerja = false;
  String? errorProgramKerja;

  // ── Supervisi state ──
  List<SupervisiModel> supervisiList = [];
  bool isLoadingSupervisi = false;
  String? errorSupervisi;

  // ── Jadwal state ──
  List<Map<String, dynamic>> jadwalList = [];
  bool isLoadingJadwal = false;
  String? errorJadwal;

  // ── Guru list (for supervisi form) ──
  List<Map<String, dynamic>> guruList = [];

  // ═══════════════════════════════════════════════════
  // PROGRAM KERJA
  // ═══════════════════════════════════════════════════

  Future<void> fetchProgramKerja() async {
    isLoadingProgramKerja = true;
    errorProgramKerja = null;
    notifyListeners();
    try {
      final response = await _dioClient.get(ApiEndpoints.wakilProgramKerja);
      final raw = response.data;
      List<dynamic> rows = [];
      if (raw is List) {
        rows = raw;
      } else if (raw is Map<String, dynamic>) {
        rows = raw['data'] is List ? raw['data'] as List : [];
      }
      programKerjaList = rows
          .map((e) => ProgramKerjaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      errorProgramKerja = 'Gagal memuat program kerja';
    } finally {
      isLoadingProgramKerja = false;
      notifyListeners();
    }
  }

  Future<bool> createProgramKerja(Map<String, dynamic> data) async {
    try {
      await _dioClient.post(ApiEndpoints.wakilProgramKerja, data: data);
      await fetchProgramKerja();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProgramKerja(int id, Map<String, dynamic> data) async {
    try {
      await _dioClient.put('${ApiEndpoints.wakilProgramKerja}/$id', data: data);
      await fetchProgramKerja();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProgramKerja(int id) async {
    try {
      await _dioClient.delete('${ApiEndpoints.wakilProgramKerja}/$id');
      await fetchProgramKerja();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════
  // SUPERVISI
  // ═══════════════════════════════════════════════════

  Future<void> fetchSupervisi() async {
    isLoadingSupervisi = true;
    errorSupervisi = null;
    notifyListeners();
    try {
      final response = await _dioClient.get(ApiEndpoints.wakilSupervisi);
      final raw = response.data;
      List<dynamic> rows = [];
      if (raw is List) {
        rows = raw;
      } else if (raw is Map<String, dynamic>) {
        rows = raw['data'] is List ? raw['data'] as List : [];
      }
      supervisiList = rows
          .map((e) => SupervisiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      errorSupervisi = 'Gagal memuat data supervisi';
    } finally {
      isLoadingSupervisi = false;
      notifyListeners();
    }
  }

  Future<bool> createSupervisi(Map<String, dynamic> data) async {
    try {
      await _dioClient.post(ApiEndpoints.wakilSupervisi, data: data);
      await fetchSupervisi();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateSupervisi(int id, Map<String, dynamic> data) async {
    try {
      await _dioClient.put('${ApiEndpoints.wakilSupervisi}/$id', data: data);
      await fetchSupervisi();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSupervisi(int id) async {
    try {
      await _dioClient.delete('${ApiEndpoints.wakilSupervisi}/$id');
      await fetchSupervisi();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════
  // JADWAL MONITORING
  // ═══════════════════════════════════════════════════

  Future<void> fetchJadwal() async {
    isLoadingJadwal = true;
    errorJadwal = null;
    notifyListeners();
    try {
      final response = await _dioClient.get(ApiEndpoints.schedules);
      final raw = response.data;
      List<dynamic> rows = [];
      if (raw is List) {
        rows = raw;
      } else if (raw is Map<String, dynamic>) {
        rows = raw['data'] is List ? raw['data'] as List : [];
      }
      jadwalList = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      errorJadwal = 'Gagal memuat data jadwal';
    } finally {
      isLoadingJadwal = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════
  // GURU LIST
  // ═══════════════════════════════════════════════════

  Future<void> fetchGuru() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.teachers);
      final raw = response.data;
      List<dynamic> rows = [];
      if (raw is List) {
        rows = raw;
      } else if (raw is Map<String, dynamic>) {
        rows = raw['data'] is List ? raw['data'] as List : [];
      }
      guruList = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      notifyListeners();
    } catch (_) {}
  }
}
