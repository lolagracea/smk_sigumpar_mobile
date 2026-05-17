// lib/features/vokasi/pkl_nilai/data/repositories/pkl_nilai_repository.dart

import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/pkl_input_nilai_model.dart';

abstract class PklNilaiRepository {
  /// Ambil semua kelas dari academic service
  Future<List<ClassModel>> getKelas();

  /// Ambil daftar siswa beserta nilai PKL yang sudah ada
  Future<List<PklNilaiSiswaModel>> getSiswaWithNilaiPkl({
    required int kelasId,
  });

  /// Simpan/update nilai PKL secara bulk
  Future<void> saveBulkNilaiPkl({
    required int kelasId,
    required List<PklNilaiSiswaModel> rows,
  });
}
