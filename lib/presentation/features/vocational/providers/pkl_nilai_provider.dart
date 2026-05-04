// lib/features/vokasi/pkl_nilai/presentation/providers/pkl_nilai_provider.dart

import 'package:flutter/material.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/pkl_input_nilai_model.dart';
import 'package:smk_sigumpar/data/repositories/pkl_nilai_repository.dart';

enum PklNilaiLoadState { initial, loading, loaded, saving, error }

class PklNilaiProvider extends ChangeNotifier {
  final PklNilaiRepository _repository;

  PklNilaiProvider({required PklNilaiRepository repository})
      : _repository = repository;

  // ── State ──────────────────────────────────────────────────
  PklNilaiLoadState _state = PklNilaiLoadState.initial;
  List<ClassModel> _kelasList = [];
  ClassModel? _selectedKelas;
  List<PklNilaiSiswaModel> _rows = [];
  bool _sudahCari = false;
  String? _error;
  String? _successMessage;

  // ── Getters ────────────────────────────────────────────────
  PklNilaiLoadState get state => _state;
  List<ClassModel> get kelasList => _kelasList;
  ClassModel? get selectedKelas => _selectedKelas;
  List<PklNilaiSiswaModel> get rows => _rows;
  bool get sudahCari => _sudahCari;
  String? get error => _error;
  String? get successMessage => _successMessage;

  bool get isLoading => _state == PklNilaiLoadState.loading;
  bool get isSaving => _state == PklNilaiLoadState.saving;

  // ── Load daftar kelas ──────────────────────────────────────
  Future<void> loadKelas() async {
    if (_kelasList.isNotEmpty) return; // Sudah di-load, skip
    _state = PklNilaiLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _kelasList = await _repository.getKelas();
      _state = PklNilaiLoadState.loaded;
    } catch (e) {
      _error = 'Gagal memuat daftar kelas: ${e.toString()}';
      _state = PklNilaiLoadState.error;
    }
    notifyListeners();
  }

  // ── Pilih kelas ────────────────────────────────────────────
  void selectKelas(ClassModel? kelas) {
    _selectedKelas = kelas;
    _rows = [];
    _sudahCari = false;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  // ── Tampilkan siswa (fetch) ────────────────────────────────
  Future<void> fetchSiswaWithNilai() async {
    if (_selectedKelas == null) return;

    _state = PklNilaiLoadState.loading;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      _rows = await _repository.getSiswaWithNilaiPkl(
        kelasId: int.parse(_selectedKelas!.id),
      );
      _sudahCari = true;
      _state = PklNilaiLoadState.loaded;
    } catch (e) {
      _error = 'Gagal memuat data siswa: ${e.toString()}';
      _state = PklNilaiLoadState.error;
    }
    notifyListeners();
  }

  // ── Update nilai satu siswa (lokal) ───────────────────────
  void updateNilai({
    required int siswaId,
    required String field, // 'industri' | 'sekolah'
    required double value,
  }) {
    final idx = _rows.indexWhere((r) => r.siswaId == siswaId);
    if (idx == -1) return;

    final row = _rows[idx];
    _rows[idx] = row.copyWith(
      nilaiIndustri: field == 'industri' ? value : row.nilaiIndustri,
      nilaiSekolah: field == 'sekolah' ? value : row.nilaiSekolah,
    );
    notifyListeners();
  }

  // ── Simpan semua nilai (POST bulk) ─────────────────────────
  Future<void> saveNilai() async {
    if (_selectedKelas == null || _rows.isEmpty) return;

    _state = PklNilaiLoadState.saving;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.saveBulkNilaiPkl(
        kelasId: int.parse(_selectedKelas!.id),
        rows: _rows,
      );
      _successMessage = 'Nilai PKL berhasil disimpan.';
      _state = PklNilaiLoadState.loaded;
    } catch (e) {
      _error = 'Gagal menyimpan nilai: ${e.toString()}';
      _state = PklNilaiLoadState.error;
    }
    notifyListeners();
  }

  // ── Reset pesan ───────────────────────────────────────────
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
