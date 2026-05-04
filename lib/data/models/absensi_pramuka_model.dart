/// Model untuk data siswa vokasional/pramuka
class SiswaPramukaModel {
  final String id;
  final String namaLengkap;
  final String? nisn;
  final String? kelasId;

  const SiswaPramukaModel({
    required this.id,
    required this.namaLengkap,
    this.nisn,
    this.kelasId,
  });

  factory SiswaPramukaModel.fromJson(Map<String, dynamic> json) {
    return SiswaPramukaModel(
      id: json['id']?.toString() ?? '',
      namaLengkap:
          json['nama_lengkap'] ?? json['nama_siswa'] ?? json['name'] ?? '-',
      nisn: json['nisn']?.toString(),
      kelasId: json['kelas_id']?.toString(),
    );
  }
}

/// Model untuk kelas vokasional/pramuka
class KelasVokasionalModel {
  final String id;
  final String namaKelas;

  const KelasVokasionalModel({
    required this.id,
    required this.namaKelas,
  });

  factory KelasVokasionalModel.fromJson(Map<String, dynamic> json) {
    return KelasVokasionalModel(
      id: json['id']?.toString() ?? '',
      namaKelas: json['nama_kelas'] ?? json['nama'] ?? json['name'] ?? '-',
    );
  }
}

/// Model untuk item riwayat absensi pramuka (per-baris dari backend)
class RiwayatAbsensiPramukaModel {
  final String id;
  final String tanggal;
  final String namaLengkap;
  final String? kelasId;
  final String status; // hadir | izin | sakit | alpa
  final String? keterangan;

  const RiwayatAbsensiPramukaModel({
    required this.id,
    required this.tanggal,
    required this.namaLengkap,
    this.kelasId,
    required this.status,
    this.keterangan,
  });

  factory RiwayatAbsensiPramukaModel.fromJson(Map<String, dynamic> json) {
    return RiwayatAbsensiPramukaModel(
      id: json['id']?.toString() ?? '',
      tanggal: (json['tanggal'] ?? '').toString().substring(0, 10),
      namaLengkap: json['nama_lengkap'] ?? json['nama_siswa'] ?? '-',
      kelasId: json['kelas_id']?.toString(),
      status: json['status'] ?? '',
      keterangan: json['keterangan']?.toString(),
    );
  }
}

/// Model untuk data rekap absensi per siswa
class RekapAbsensiSiswaModel {
  final String siswaId;
  final int hadir;
  final int izin;
  final int sakit;
  final int alpa;
  final int total;

  const RekapAbsensiSiswaModel({
    required this.siswaId,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alpa,
    required this.total,
  });

  factory RekapAbsensiSiswaModel.fromJson(Map<String, dynamic> json) {
    final h = int.tryParse(json['hadir']?.toString() ?? '0') ?? 0;
    final i = int.tryParse(json['izin']?.toString() ?? '0') ?? 0;
    final s = int.tryParse(json['sakit']?.toString() ?? '0') ?? 0;
    final a = int.tryParse(json['alpa']?.toString() ?? '0') ?? 0;
    return RekapAbsensiSiswaModel(
      siswaId: json['siswa_id']?.toString() ?? '',
      hadir: h,
      izin: i,
      sakit: s,
      alpa: a,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? (h + i + s + a),
    );
  }
}

/// Enum status absensi — mirror web STATUS_OPTS
enum StatusAbsensi { hadir, izin, sakit, alpa }

extension StatusAbsensiExt on StatusAbsensi {
  String get value {
    switch (this) {
      case StatusAbsensi.hadir:
        return 'hadir';
      case StatusAbsensi.izin:
        return 'izin';
      case StatusAbsensi.sakit:
        return 'sakit';
      case StatusAbsensi.alpa:
        return 'alpa';
    }
  }

  String get label {
    switch (this) {
      case StatusAbsensi.hadir:
        return 'Hadir';
      case StatusAbsensi.izin:
        return 'Izin';
      case StatusAbsensi.sakit:
        return 'Sakit';
      case StatusAbsensi.alpa:
        return 'Alpa';
    }
  }
}

/// Helper: parse string → StatusAbsensi?
StatusAbsensi? statusAbsensiFromString(String? s) {
  switch (s) {
    case 'hadir':
      return StatusAbsensi.hadir;
    case 'izin':
      return StatusAbsensi.izin;
    case 'sakit':
      return StatusAbsensi.sakit;
    case 'alpa':
      return StatusAbsensi.alpa;
    default:
      return null;
  }
}