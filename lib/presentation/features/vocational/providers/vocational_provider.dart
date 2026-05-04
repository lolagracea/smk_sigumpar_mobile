import 'package:flutter/material.dart';
import 'package:smk_sigumpar/data/repositories/vocational_repository.dart';
import 'package:smk_sigumpar/data/models/absensi_pramuka_model.dart';

enum VocationalLoadState { initial, loading, loaded, error }

/// ─────────────────────────────────────────────────────────────
/// VocationalProvider — state management untuk modul PRAMUKA
///
/// Mengelola:
/// - Daftar kelas/regu pramuka  (existing)
/// - Absensi pramuka            (existing + NEW full feature)
/// - Laporan kegiatan pramuka   (existing)
///
/// NEW STATE untuk AbsensiPramukaScreen (3 tab: input, riwayat, rekap):
/// - kelasVokasionalList    : daftar kelas dari /api/vocational/kelas
/// - siswaList              : daftar siswa per kelas
/// - absensiMap             : { siswaId → {status, keterangan} }
/// - riwayatAbsensi         : list riwayat
/// - rekapSiswa + rekapData : data rekap
/// ─────────────────────────────────────────────────────────────
class VocationalProvider extends ChangeNotifier {
  final VocationalRepository _repository;

  VocationalProvider({required VocationalRepository repository})
      : _repository = repository;

  // ── State ──────────────────────────────────────────────────
  VocationalLoadState _state = VocationalLoadState.initial;
  String? _error;

  // ── Scout Classes (Regu/Kelas Pramuka) ─────────────────────
  List<Map<String, dynamic>> _scoutClasses = [];

  // ── Scout Attendance (Absensi Pramuka - legacy list) ───────
  List<Map<String, dynamic>> _scoutAttendance = [];

  // ── Scout Activity Reports (Laporan Kegiatan) ───────────────
  List<Map<String, dynamic>> _scoutReports = [];

  // ── NEW: Kelas Vokasional ────────────────────────────────────
  List<KelasVokasionalModel> _kelasVokasionalList = [];
  bool _loadingKelas = false;

  // ── NEW: Tab Input — Siswa & Absensi Map ────────────────────
  List<SiswaPramukaModel> _siswaList = [];
  bool _loadingSiswa = false;

  /// Map<siswaId, {status: String?, keterangan: String}>
  Map<String, Map<String, String>> _absensiMap = {};

  bool _saving = false;

  // ── NEW: Tab Riwayat ─────────────────────────────────────────
  List<RiwayatAbsensiPramukaModel> _riwayatAbsensi = [];
  bool _loadingRiwayat = false;

  // ── NEW: Tab Rekap ───────────────────────────────────────────
  List<SiswaPramukaModel> _rekapSiswaList = [];
  List<RekapAbsensiSiswaModel> _rekapData = [];
  bool _loadingRekap = false;

  // ── Getters (existing) ─────────────────────────────────────
  VocationalLoadState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == VocationalLoadState.loading;
  bool get hasError => _state == VocationalLoadState.error;

  List<Map<String, dynamic>> get scoutClasses => _scoutClasses;
  List<Map<String, dynamic>> get scoutAttendance => _scoutAttendance;
  List<Map<String, dynamic>> get scoutReports => _scoutReports;

  // ── Getters (NEW) ───────────────────────────────────────────
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

  /// Summary untuk tab input (mirror web `summary` useMemo)
  Map<String, int> get absensiSummary {
    final s = {'hadir': 0, 'izin': 0, 'sakit': 0, 'alpa': 0, 'belum': 0, 'total': _siswaList.length};
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

  // ── Existing methods (unchanged) ────────────────────────────

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

  Future<void> fetchScoutReports({bool refresh = false}) async {
    if (refresh) _scoutReports = [];
    _setState(VocationalLoadState.loading);
    try {
      final result = await _repository.getScoutReports();
      _scoutReports = result.items;
      _setState(VocationalLoadState.loaded);
    } catch (e) {
      _error = _parseError(e);
      _setState(VocationalLoadState.error);
    }
  }

  Future<bool> createScoutReport(Map<String, dynamic> data) async {
    _setState(VocationalLoadState.loading);
    try {
      final newReport = await _repository.createScoutReport(data);
      _scoutReports = [newReport, ..._scoutReports];
      _setState(VocationalLoadState.loaded);
      return true;
    } catch (e) {
      _error = _parseError(e);
      _setState(VocationalLoadState.error);
      return false;
    }
  }

  // ── NEW: Absensi Pramuka methods (mirror web) ───────────────

  /// Load daftar kelas vokasional (dipanggil di initState AbsensiPramukaScreen)
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

  /// Load daftar siswa berdasarkan kelas (dipanggil saat selectedKelas berubah)
  /// Mirror web: loadSiswaByKelas(kelasId)
  Future<void> loadSiswaPramuka(String kelasId) async {
    _siswaList = [];
    _absensiMap = {};
    _loadingSiswa = true;
    notifyListeners();

    try {
      final raw = await _repository.getSiswaPramuka(kelasId: kelasId);
      _siswaList = raw.map(SiswaPramukaModel.fromJson).toList();

      // Init absensiMap — mirror web initialAbsensi
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

  /// Reset siswa list saat kelas di-clear
  void clearSiswaList() {
    _siswaList = [];
    _absensiMap = {};
    notifyListeners();
  }

  /// Set status absensi satu siswa — mirror web setStatus(siswaId, status)
  void setAbsensiStatus(String siswaId, String status) {
    _absensiMap = {
      ..._absensiMap,
      siswaId: {
        ...(_absensiMap[siswaId] ?? {}),
        'status': status,
      },
    };
    notifyListeners();
  }

  /// Set keterangan satu siswa — mirror web setKeterangan(siswaId, keterangan)
  void setAbsensiKeterangan(String siswaId, String keterangan) {
    _absensiMap = {
      ..._absensiMap,
      siswaId: {
        ...(_absensiMap[siswaId] ?? {}),
        'keterangan': keterangan,
      },
    };
    notifyListeners();
  }

  /// Tandai semua siswa dengan satu status — mirror web tandaiSemua(status)
  void tandaiSemuaStatus(String status) {
    final next = <String, Map<String, String>>{};
    for (final siswa in _siswaList) {
      next[siswa.id] = {
        ...(_absensiMap[siswa.id] ?? {}),
        'status': status,
      };
    }
    _absensiMap = next;
    notifyListeners();
  }

  /// Submit absensi bulk — mirror web handleSimpan()
  /// Returns (success, errorMessage?)
  Future<(bool, String?)> submitAbsensiPramukaBulk({
    required String kelasId,
    required String tanggal,
    required String deskripsi,
  }) async {
    // Validasi — mirror web
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

  /// Load riwayat absensi — mirror web handleLoadRiwayat()
  Future<void> loadRiwayatAbsensi({String? kelasId, String? tanggal}) async {
    _loadingRiwayat = true;
    notifyListeners();
    try {
      final raw = await _repository.getRiwayatAbsensiPramuka(
        kelasId: kelasId,
        tanggal: tanggal,
      );
      _riwayatAbsensi = raw.map(RiwayatAbsensiPramukaModel.fromJson).toList();
    } catch (e) {
      _error = _parseError(e);
      _riwayatAbsensi = [];
    } finally {
      _loadingRiwayat = false;
      notifyListeners();
    }
  }

  /// Load rekap absensi — mirror web handleLoadRekap()
  Future<void> loadRekapAbsensi({
    required String kelasId,
    String? tanggalMulai,
    String? tanggalAkhir,
  }) async {
    _loadingRekap = true;
    notifyListeners();
    try {
      // Parallel load siswa + rekap — mirror web Promise.all
      final results = await Future.wait([
        _repository.getSiswaPramuka(kelasId: kelasId),
        _repository.getRekapAbsensiPramuka(
          kelasId: kelasId,
          tanggalMulai: tanggalMulai,
          tanggalAkhir: tanggalAkhir,
        ),
      ]);

      final rawSiswa = results[0] as List<Map<String, dynamic>>;
      final rawRekap = results[1] as List<Map<String, dynamic>>;

      _rekapSiswaList = rawSiswa.map(SiswaPramukaModel.fromJson).toList();
      _rekapData = rawRekap.map(RekapAbsensiSiswaModel.fromJson).toList();
    } catch (e) {
      _error = _parseError(e);
      _rekapSiswaList = [];
      _rekapData = [];
    } finally {
      _loadingRekap = false;
      notifyListeners();
    }
  }

  /// Clear riwayat (reset sebelum load baru)
  void clearRiwayat() {
    _riwayatAbsensi = [];
    notifyListeners();
  }

  /// Clear rekap
  void clearRekap() {
    _rekapSiswaList = [];
    _rekapData = [];
    notifyListeners();
  }

  /// Helper: cari rekap by siswaId — mirror web getRekapBySiswa(siswaId)
  RekapAbsensiSiswaModel? getRekapBySiswaId(String siswaId) {
    try {
      return _rekapData.firstWhere(
        (r) => r.siswaId == siswaId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Helper: cari nama kelas berdasarkan ID — mirror web getNamaKelas(kelasId)
  String getNamaKelasById(String kelasId) {
    try {
      return _kelasVokasionalList
          .firstWhere((k) => k.id == kelasId)
          .namaKelas;
    } catch (_) {
      return '-';
    }
  }

  // ── Helpers ───────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setState(VocationalLoadState state) {
    _state = state;
    notifyListeners();
  }

  String _parseError(Object e) {
    return e.toString().replaceAll('NetworkExceptions: ', '');
  }
}