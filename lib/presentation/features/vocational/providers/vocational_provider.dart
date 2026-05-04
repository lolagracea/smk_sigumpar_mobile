// ─────────────────────────────────────────────────────────────────────────────
// lib/presentation/features/vocational/providers/vocational_provider.dart
//
// VocationalProvider — state management untuk modul PRAMUKA
//
// Mengelola:
//   - Daftar kelas/regu pramuka       (existing)
//   - Absensi pramuka                 (existing + full feature)
//   - Laporan Kegiatan Pramuka        (NEW — mirror web LaporanKegiatanPage)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smk_sigumpar/data/repositories/vocational_repository.dart';
import 'package:smk_sigumpar/data/models/absensi_pramuka_model.dart';
import 'package:smk_sigumpar/data/models/laporan_kegiatan_model.dart';

enum VocationalLoadState { initial, loading, loaded, error }

class VocationalProvider extends ChangeNotifier {
  final VocationalRepository _repository;

  VocationalProvider({required VocationalRepository repository})
      : _repository = repository;

  // ── Global State ─────────────────────────────────────────────
  VocationalLoadState _state = VocationalLoadState.initial;
  String? _error;

  // ── Scout Classes (Regu/Kelas Pramuka) ───────────────────────
  List<Map<String, dynamic>> _scoutClasses = [];

  // ── Scout Attendance (legacy list) ───────────────────────────
  List<Map<String, dynamic>> _scoutAttendance = [];

  // ── Scout Reports (Laporan Kegiatan) — FULL FEATURE ──────────
  List<LaporanKegiatanModel> _laporanKegiatan = [];
  bool _loadingLaporan = false;
  bool _savingLaporan = false;
  String? _laporanError;

  // ── Kelas Vokasional ─────────────────────────────────────────
  List<KelasVokasionalModel> _kelasVokasionalList = [];
  bool _loadingKelas = false;

  // ── Tab Input — Siswa & Absensi Map ──────────────────────────
  List<SiswaPramukaModel> _siswaList = [];
  bool _loadingSiswa = false;
  Map<String, Map<String, String>> _absensiMap = {};
  bool _saving = false;

  // ── Tab Riwayat ───────────────────────────────────────────────
  List<RiwayatAbsensiPramukaModel> _riwayatAbsensi = [];
  bool _loadingRiwayat = false;

  // ── Tab Rekap ─────────────────────────────────────────────────
  List<SiswaPramukaModel> _rekapSiswaList = [];
  List<RekapAbsensiSiswaModel> _rekapData = [];
  bool _loadingRekap = false;

  // ── Getters (existing) ───────────────────────────────────────
  VocationalLoadState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == VocationalLoadState.loading;
  bool get hasError => _state == VocationalLoadState.error;

  List<Map<String, dynamic>> get scoutClasses => _scoutClasses;
  List<Map<String, dynamic>> get scoutAttendance => _scoutAttendance;

  // ── Getters — Laporan Kegiatan (NEW) ─────────────────────────
  List<LaporanKegiatanModel> get laporanKegiatan => _laporanKegiatan;
  bool get loadingLaporan => _loadingLaporan;
  bool get savingLaporan => _savingLaporan;
  String? get laporanError => _laporanError;

  // ── Getters — Absensi (existing) ─────────────────────────────
  List<KelasVokasionalModel> get kelasVokasionalList => _kelasVokasionalList;
  bool get loadingKelas => _loadingKelas;
  List<SiswaPramukaModel> get siswaList => _siswaList;
  bool get loadingSiswa => _loadingSiswa;
  Map<String, Map<String, String>> get absensiMap => _absensiMap;
  bool get saving => _saving;
  List<RiwayatAbsensiPramukaModel> get riwayatAbsensi => _riwayatAbsensi;
  bool get loadingRiwayat => _loadingRiwayat;
  List<SiswaPramukaModel> get rekapSiswaList => _rekapSiswaList;
  List<RekapAbsensiSiswaModel> get rekapData => _rekapData;
  bool get loadingRekap => _loadingRekap;

  Map<String, int> get absensiSummary {
    final s = {
      'hadir': 0, 'izin': 0, 'sakit': 0, 'alpa': 0,
      'belum': 0, 'total': _siswaList.length
    };
    for (final siswa in _siswaList) {
      final status = _absensiMap[siswa.id]?['status'] ?? '';
      if (['hadir', 'izin', 'sakit', 'alpa'].contains(status)) {
        s[status] = (s[status] ?? 0) + 1;
      } else {
        s['belum'] = (s['belum'] ?? 0) + 1;
      }
    }
    return s;
  }

  // ════════════════════════════════════════════════════════════
  // LAPORAN KEGIATAN — mirror web LaporanKegiatanPage
  // ════════════════════════════════════════════════════════════

  /// Load semua laporan kegiatan — mirror web loadLaporan()
  Future<void> fetchLaporanKegiatan({bool refresh = false}) async {
    if (refresh) _laporanKegiatan = [];
    _loadingLaporan = true;
    _laporanError = null;
    notifyListeners();
    try {
      _laporanKegiatan = await _repository.getAllLaporanKegiatan();
    } catch (e) {
      _laporanError = _parseError(e);
    } finally {
      _loadingLaporan = false;
      notifyListeners();
    }
  }

  /// Buat laporan baru dengan optional file — mirror web handleSimpan()
  ///
  /// [judul]     : wajib
  /// [deskripsi] : opsional
  /// [tanggal]   : wajib (format YYYY-MM-DD)
  /// [fileBytes] : opsional — bytes file dari file_picker
  /// [fileName]  : nama file asli (mis: laporan.pdf)
  /// [fileMime]  : MIME type (mis: application/pdf)
  ///
  /// Returns (success, errorMessage?)
  Future<(bool, String?)> createLaporanKegiatan({
    required String judul,
    required String tanggal,
    String? deskripsi,
    List<int>? fileBytes,
    String? fileName,
    String? fileMime,
  }) async {
    if (judul.trim().isEmpty) return (false, 'Judul laporan wajib diisi');

    _savingLaporan = true;
    notifyListeners();

    try {
      // Build multipart FormData — mirror web FormData() di handleSimpan()
      final formData = FormData.fromMap({
        'judul': judul.trim(),
        'deskripsi': deskripsi?.trim() ?? '',
        'tanggal': tanggal,
        if (fileBytes != null && fileName != null)
          'file_laporan': MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
            contentType: _parseDioMediaType(fileMime),
          ),
      });

      final newLaporan = await _repository.createLaporanKegiatan(formData);
      // Prepend ke list — mirror web: loadLaporan() setelah save (ORDER BY tanggal DESC)
      _laporanKegiatan = [newLaporan, ..._laporanKegiatan];
      return (true, null);
    } catch (e) {
      return (false, _parseError(e));
    } finally {
      _savingLaporan = false;
      notifyListeners();
    }
  }

  /// Hapus laporan — mirror web handleHapus(id, judul)
  /// Returns (success, errorMessage?)
  Future<(bool, String?)> deleteLaporanKegiatan(int id) async {
    try {
      await _repository.deleteLaporanKegiatan(id);
      _laporanKegiatan = _laporanKegiatan.where((l) => l.id != id).toList();
      notifyListeners();
      return (true, null);
    } catch (e) {
      return (false, _parseError(e));
    }
  }

  /// View file laporan — mirror web vocationalApi.viewLaporanKegiatan()
  /// Returns raw bytes untuk ditampilkan di mobile (image viewer / PDF viewer)
  Future<(List<int>?, String?, String?)> viewLaporanFile(int id) async {
    try {
      final r = await _repository.viewLaporanKegiatanFile(id);
      final bytes = r.data;
      final mime = r.headers.value('content-type') ?? 'application/octet-stream';
      return (bytes, mime, null);
    } catch (e) {
      return (null, null, _parseError(e));
    }
  }

  /// Download file laporan — mirror web vocationalApi.downloadLaporanKegiatan()
  Future<(List<int>?, String?)> downloadLaporanFile(int id) async {
    try {
      final r = await _repository.downloadLaporanKegiatanFile(id);
      return (r.data, null);
    } catch (e) {
      return (null, _parseError(e));
    }
  }

  // ════════════════════════════════════════════════════════════
  // SCOUT CLASSES (existing)
  // ════════════════════════════════════════════════════════════

  Future<void> fetchScoutClasses({bool refresh = false}) async {
    if (refresh) _scoutClasses = [];
    _setState(VocationalLoadState.loading);
    try {
      final result = await _repository.getScoutClasses();
      _scoutClasses = result.items;
      _setState(VocationalLoadState.loaded);
    } catch (e) {
      _error = _parseError(e);
      _setState(VocationalLoadState.error);
    }
  }

  Future<void> fetchScoutAttendance({bool refresh = false, String? classId}) async {
    if (refresh) _scoutAttendance = [];
    _setState(VocationalLoadState.loading);
    try {
      final result = await _repository.getScoutAttendance(classId: classId);
      _scoutAttendance = result.items;
      _setState(VocationalLoadState.loaded);
    } catch (e) {
      _error = _parseError(e);
      _setState(VocationalLoadState.error);
    }
  }

  Future<bool> submitScoutAttendance(Map<String, dynamic> data) async {
    _setState(VocationalLoadState.loading);
    try {
      await _repository.submitScoutAttendance(data);
      _setState(VocationalLoadState.loaded);
      return true;
    } catch (e) {
      _error = _parseError(e);
      _setState(VocationalLoadState.error);
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // ABSENSI PRAMUKA BULK (existing)
  // ════════════════════════════════════════════════════════════

  Future<void> loadKelasVokasional() async {
    _loadingKelas = true;
    notifyListeners();
    try {
      final raw = await _repository.getKelasVokasional();
      _kelasVokasionalList = raw.map(KelasVokasionalModel.fromJson).toList();
    } catch (e) {
      _error = _parseError(e);
    } finally {
      _loadingKelas = false;
      notifyListeners();
    }
  }

  Future<void> loadSiswaPramuka(String kelasId) async {
    _siswaList = [];
    _absensiMap = {};
    _loadingSiswa = true;
    notifyListeners();
    try {
      final raw = await _repository.getSiswaPramuka(kelasId: kelasId);
      _siswaList = raw.map(SiswaPramukaModel.fromJson).toList();
      final initMap = <String, Map<String, String>>{};
      for (final siswa in _siswaList) {
        initMap[siswa.id] = {'status': '', 'keterangan': ''};
      }
      _absensiMap = initMap;
    } catch (e) {
      _error = _parseError(e);
      _siswaList = [];
      _absensiMap = {};
    } finally {
      _loadingSiswa = false;
      notifyListeners();
    }
  }

  void clearSiswaList() {
    _siswaList = [];
    _absensiMap = {};
    notifyListeners();
  }

  void setAbsensiStatus(String siswaId, String status) {
    _absensiMap = {
      ..._absensiMap,
      siswaId: {...(_absensiMap[siswaId] ?? {}), 'status': status},
    };
    notifyListeners();
  }

  void setAbsensiKeterangan(String siswaId, String keterangan) {
    _absensiMap = {
      ..._absensiMap,
      siswaId: {...(_absensiMap[siswaId] ?? {}), 'keterangan': keterangan},
    };
    notifyListeners();
  }

  void tandaiSemuaStatus(String status) {
    final next = <String, Map<String, String>>{};
    for (final siswa in _siswaList) {
      next[siswa.id] = {...(_absensiMap[siswa.id] ?? {}), 'status': status};
    }
    _absensiMap = next;
    notifyListeners();
  }

  Future<(bool, String?)> submitAbsensiPramukaBulk({
    required String kelasId,
    required String tanggal,
    required String deskripsi,
  }) async {
    if (_siswaList.isEmpty) return (false, 'Tidak ada siswa di kelas ini');
    final belumDiisi = _siswaList.where((s) => (_absensiMap[s.id]?['status'] ?? '').isEmpty).toList();
    if (belumDiisi.isNotEmpty) {
      return (false, 'Semua siswa harus diberi status absensi terlebih dahulu');
    }
    _saving = true;
    notifyListeners();
    try {
      final payload = {
        'kelas_id': kelasId,
        'tanggal': tanggal,
        'deskripsi': deskripsi,
        'data_absensi': _siswaList.map((siswa) => {
          'siswa_id': siswa.id,
          'nama_lengkap': siswa.namaLengkap,
          'nisn': siswa.nisn,
          'status': _absensiMap[siswa.id]?['status'] ?? '',
          'keterangan': _absensiMap[siswa.id]?['keterangan'] ?? '',
        }).toList(),
      };
      await _repository.submitAbsensiPramukaBulk(payload);
      return (true, null);
    } catch (e) {
      return (false, _parseError(e));
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> loadRiwayatAbsensi({String? kelasId, String? tanggal}) async {
    _loadingRiwayat = true;
    notifyListeners();
    try {
      final raw = await _repository.getRiwayatAbsensiPramuka(kelasId: kelasId, tanggal: tanggal);
      _riwayatAbsensi = raw.map(RiwayatAbsensiPramukaModel.fromJson).toList();
    } catch (e) {
      _error = _parseError(e);
      _riwayatAbsensi = [];
    } finally {
      _loadingRiwayat = false;
      notifyListeners();
    }
  }

  Future<void> loadRekapAbsensi({
    required String kelasId,
    String? tanggalMulai,
    String? tanggalAkhir,
  }) async {
    _loadingRekap = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getSiswaPramuka(kelasId: kelasId),
        _repository.getRekapAbsensiPramuka(
          kelasId: kelasId,
          tanggalMulai: tanggalMulai,
          tanggalAkhir: tanggalAkhir,
        ),
      ]);
      _rekapSiswaList = (results[0] as List<Map<String, dynamic>>).map(SiswaPramukaModel.fromJson).toList();
      _rekapData = (results[1] as List<Map<String, dynamic>>).map(RekapAbsensiSiswaModel.fromJson).toList();
    } catch (e) {
      _error = _parseError(e);
      _rekapSiswaList = [];
      _rekapData = [];
    } finally {
      _loadingRekap = false;
      notifyListeners();
    }
  }

  void clearRiwayat() { _riwayatAbsensi = []; notifyListeners(); }
  void clearRekap() { _rekapSiswaList = []; _rekapData = []; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }

  RekapAbsensiSiswaModel? getRekapBySiswaId(String siswaId) {
    try { return _rekapData.firstWhere((r) => r.siswaId == siswaId); } catch (_) { return null; }
  }

  String getNamaKelasById(String kelasId) {
    try { return _kelasVokasionalList.firstWhere((k) => k.id == kelasId).namaKelas; } catch (_) { return '-'; }
  }

  // ── Helpers ──────────────────────────────────────────────────

  void _setState(VocationalLoadState state) {
    _state = state;
    notifyListeners();
  }

  String _parseError(Object e) {
    return e.toString().replaceAll('NetworkExceptions: ', '').replaceAll('Exception: ', '');
  }

  /// Parse MIME string ke DioMediaType (untuk MultipartFile)
  DioMediaType? _parseDioMediaType(String? mime) {
    if (mime == null) return null;
    final parts = mime.split('/');
    if (parts.length == 2) return DioMediaType(parts[0], parts[1]);
    return null;
  }
}