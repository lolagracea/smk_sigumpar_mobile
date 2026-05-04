// lib/features/vokasi/pkl_nilai/data/models/pkl_nilai_model.dart

class PklNilaiSiswaModel {
  final int? id;
  final int siswaId;
  final String? nis;
  final String namaSiswa;
  final int? kelasId;
  final String? namaKelas;
  final String? tempatPkl;
  final double? nilaiIndustri;
  final double? nilaiSekolah;
  double? nilaiAkhir;

  PklNilaiSiswaModel({
    this.id,
    required this.siswaId,
    this.nis,
    required this.namaSiswa,
    this.kelasId,
    this.namaKelas,
    this.tempatPkl,
    this.nilaiIndustri,
    this.nilaiSekolah,
    this.nilaiAkhir,
  }) {
    nilaiAkhir = _hitung();
  }

  double _hitung() {
    final ind = nilaiIndustri ?? 0;
    final sek = nilaiSekolah ?? 0;
    return (ind + sek) / 2;
  }

  factory PklNilaiSiswaModel.fromJson(Map<String, dynamic> json) {
    return PklNilaiSiswaModel(
      id: json['id'] as int?,
      siswaId: (json['siswa_id'] ?? json['id_siswa'] ?? 0) as int,
      nis: json['nis']?.toString(),
      namaSiswa:
      json['nama_siswa']?.toString() ?? json['namasiswa']?.toString() ?? '',
      kelasId: json['kelas_id'] as int?,
      namaKelas: json['nama_kelas']?.toString() ?? json['class_name']?.toString(),
      tempatPkl: json['tempat_pkl']?.toString(),
      nilaiIndustri: _toDouble(json['nilai_industri']),
      nilaiSekolah: _toDouble(json['nilai_sekolah']),
    );
  }

  static double? _toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  PklNilaiSiswaModel copyWith({
    double? nilaiIndustri,
    double? nilaiSekolah,
  }) {
    return PklNilaiSiswaModel(
      id: id,
      siswaId: siswaId,
      nis: nis,
      namaSiswa: namaSiswa,
      kelasId: kelasId,
      namaKelas: namaKelas,
      tempatPkl: tempatPkl,
      nilaiIndustri: nilaiIndustri ?? this.nilaiIndustri,
      nilaiSekolah: nilaiSekolah ?? this.nilaiSekolah,
    );
  }

  Map<String, dynamic> toJson() => {
    'siswa_id': siswaId,
    if (kelasId != null) 'kelas_id': kelasId,
    'nilai_industri': nilaiIndustri ?? 0,
    'nilai_sekolah': nilaiSekolah ?? 0,
  };

  String get predikat {
    final na = nilaiAkhir ?? 0;
    if (na >= 90) return 'Sangat Baik';
    if (na >= 80) return 'Baik';
    if (na >= 70) return 'Cukup';
    return 'Kurang';
  }

  String get inisial {
    final words = namaSiswa.split(' ');
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return namaSiswa.isNotEmpty ? namaSiswa[0].toUpperCase() : '?';
  }
}