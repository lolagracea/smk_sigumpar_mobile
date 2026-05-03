// lib/features/input_nilai/data/models/nilai_model.dart
import '../../../../../core/constants/app_constants.dart';

class NilaiSiswaModel {
  final int? id;
  final int siswaId;
  final String? nis;
  final String namaSiswa;
  final int? mapelId;
  final int? kelasId;
  final String? tahunAjar;
  final double? nilaiTugas;
  final double? nilaiKuis;
  final double? nilaiUts;
  final double? nilaiUas;
  final double? nilaiPraktik;
  double? nilaiAkhir;

  NilaiSiswaModel({
    this.id,
    required this.siswaId,
    this.nis,
    required this.namaSiswa,
    this.mapelId,
    this.kelasId,
    this.tahunAjar,
    this.nilaiTugas,
    this.nilaiKuis,
    this.nilaiUts,
    this.nilaiUas,
    this.nilaiPraktik,
    this.nilaiAkhir,
  }) {
    nilaiAkhir = _hitung();
  }

  double _hitung() {
    final t = nilaiTugas ?? 0;
    final k = nilaiKuis ?? 0;
    final u = nilaiUts ?? 0;
    final a = nilaiUas ?? 0;
    final p = nilaiPraktik ?? 0;
    final bobot = AppConstants.bobotNilai;
    return (t * bobot['tugas']! +
            k * bobot['kuis']! +
            u * bobot['uts']! +
            a * bobot['uas']! +
            p * bobot['praktik']!) /
        100;
  }

  factory NilaiSiswaModel.fromJson(Map<String, dynamic> json) {
    return NilaiSiswaModel(
      id: json['id'] as int?,
      siswaId: (json['siswa_id'] ?? json['id_siswa'] ?? 0) as int,
      nis: json['nis']?.toString(),
      namaSiswa:
          json['nama_siswa']?.toString() ?? json['namasiswa']?.toString() ?? '',
      mapelId: json['mapel_id'] as int?,
      kelasId: json['kelas_id'] as int?,
      tahunAjar: json['tahun_ajar']?.toString(),
      nilaiTugas: _toDouble(json['nilai_tugas']),
      nilaiKuis: _toDouble(json['nilai_kuis']),
      nilaiUts: _toDouble(json['nilai_uts']),
      nilaiUas: _toDouble(json['nilai_uas']),
      nilaiPraktik: _toDouble(json['nilai_praktik']),
    );
  }

  static double? _toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  NilaiSiswaModel copyWith({
    double? nilaiTugas,
    double? nilaiKuis,
    double? nilaiUts,
    double? nilaiUas,
    double? nilaiPraktik,
  }) {
    return NilaiSiswaModel(
      id: id,
      siswaId: siswaId,
      nis: nis,
      namaSiswa: namaSiswa,
      mapelId: mapelId,
      kelasId: kelasId,
      tahunAjar: tahunAjar,
      nilaiTugas: nilaiTugas ?? this.nilaiTugas,
      nilaiKuis: nilaiKuis ?? this.nilaiKuis,
      nilaiUts: nilaiUts ?? this.nilaiUts,
      nilaiUas: nilaiUas ?? this.nilaiUas,
      nilaiPraktik: nilaiPraktik ?? this.nilaiPraktik,
    );
  }

  Map<String, dynamic> toJson() => {
        'siswa_id': siswaId,
        if (mapelId != null) 'mapel_id': mapelId,
        if (kelasId != null) 'kelas_id': kelasId,
        if (tahunAjar != null) 'tahun_ajar': tahunAjar,
        'nilai_tugas': nilaiTugas ?? 0,
        'nilai_kuis': nilaiKuis ?? 0,
        'nilai_uts': nilaiUts ?? 0,
        'nilai_uas': nilaiUas ?? 0,
        'nilai_praktik': nilaiPraktik ?? 0,
      };

  String get predikat {
    final na = nilaiAkhir ?? 0;
    if (na >= 90) return 'A';
    if (na >= 80) return 'B';
    if (na >= 70) return 'C';
    if (na >= 60) return 'D';
    return 'E';
  }

  String get inisial {
    final words = namaSiswa.split(' ');
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return namaSiswa.isNotEmpty ? namaSiswa[0].toUpperCase() : '?';
  }
}
