// ─── MODEL: Guru + Status Perangkat ──────────────────────────────────────────
class GuruPerangkatModel {
  const GuruPerangkatModel({
    required this.id,
    required this.nip,
    required this.namaLengkap,
    required this.mataPelajaran,
    this.jabatan,
    required this.totalPerangkat,
    required this.perangkatLengkap,
    required this.perangkatBelumLengkap,
  });

  final int id;
  final String nip;
  final String namaLengkap;
  final String mataPelajaran;
  final String? jabatan;
  final int totalPerangkat;
  final int perangkatLengkap;
  final int perangkatBelumLengkap;

  factory GuruPerangkatModel.fromJson(Map<String, dynamic> json) {
    return GuruPerangkatModel(
      id: json['id'] as int,
      nip: json['nip']?.toString() ?? '-',
      namaLengkap: json['nama_lengkap']?.toString() ?? '-',
      mataPelajaran: json['mata_pelajaran']?.toString() ?? '-',
      jabatan: json['jabatan']?.toString(),
      totalPerangkat: int.tryParse(json['total_perangkat']?.toString() ?? '0') ?? 0,
      perangkatLengkap: int.tryParse(json['perangkat_lengkap']?.toString() ?? '0') ?? 0,
      perangkatBelumLengkap:
          int.tryParse(json['perangkat_belum_lengkap']?.toString() ?? '0') ?? 0,
    );
  }

  double get persentaseLengkap =>
      totalPerangkat == 0 ? 0 : perangkatLengkap / totalPerangkat;
}

// ─── MODEL: Perangkat Pembelajaran ───────────────────────────────────────────
class WakilPerangkatModel {
  const WakilPerangkatModel({
    required this.id,
    required this.guruId,
    required this.namaPerangkat,
    required this.jenis,
    required this.status,
    this.catatan,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int guruId;
  final String namaPerangkat;
  final String jenis;
  final String status;
  final String? catatan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isLengkap => status == 'lengkap';

  factory WakilPerangkatModel.fromJson(Map<String, dynamic> json) {
    return WakilPerangkatModel(
      id: json['id'] as int,
      guruId: json['guru_id'] as int,
      namaPerangkat: json['nama_perangkat']?.toString() ?? '-',
      jenis: json['jenis']?.toString() ?? 'RPP',
      status: json['status']?.toString() ?? 'belum_lengkap',
      catatan: json['catatan']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'guru_id': guruId,
        'nama_perangkat': namaPerangkat,
        'jenis': jenis,
        'status': status,
        'catatan': catatan,
      };
}

// ─── MODEL: Detail Guru + Daftar Perangkat ───────────────────────────────────
class GuruPerangkatDetailModel {
  const GuruPerangkatDetailModel({
    required this.guru,
    required this.perangkatList,
  });

  final GuruInfoModel guru;
  final List<WakilPerangkatModel> perangkatList;
}

class GuruInfoModel {
  const GuruInfoModel({
    required this.id,
    required this.nip,
    required this.namaLengkap,
    required this.mataPelajaran,
    this.jabatan,
  });

  final int id;
  final String nip;
  final String namaLengkap;
  final String mataPelajaran;
  final String? jabatan;

  factory GuruInfoModel.fromJson(Map<String, dynamic> json) {
    return GuruInfoModel(
      id: json['id'] as int,
      nip: json['nip']?.toString() ?? '-',
      namaLengkap: json['nama_lengkap']?.toString() ?? '-',
      mataPelajaran: json['mata_pelajaran']?.toString() ?? '-',
      jabatan: json['jabatan']?.toString(),
    );
  }
}

// ─── MODEL: Jadwal Mengajar ───────────────────────────────────────────────────
class JadwalModel {
  const JadwalModel({
    required this.id,
    required this.guruId,
    required this.kelasId,
    required this.mataPelajaran,
    required this.hari,
    required this.waktuMulai,
    required this.waktuBerakhir,
    this.namaKelas,
    required this.isBentrok,
  });

  final int id;
  final int guruId;
  final int kelasId;
  final String mataPelajaran;
  final String hari;
  final String waktuMulai;
  final String waktuBerakhir;
  final String? namaKelas;
  final bool isBentrok;

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    return JadwalModel(
      id: json['id'] as int,
      guruId: int.tryParse(json['guru_id']?.toString() ?? '0') ?? 0,
      kelasId: int.tryParse(json['kelas_id']?.toString() ?? '0') ?? 0,
      mataPelajaran: json['mata_pelajaran']?.toString() ?? '-',
      hari: json['hari']?.toString() ?? '-',
      waktuMulai: json['waktu_mulai']?.toString() ?? '-',
      waktuBerakhir: json['waktu_berakhir']?.toString() ?? '-',
      namaKelas: json['kelas']?['nama_kelas']?.toString(),
      isBentrok: json['is_bentrok'] as bool? ?? false,
    );
  }
}

// ─── MODEL: Rekap Jadwal Per Hari ─────────────────────────────────────────────
class RekapHariModel {
  const RekapHariModel({
    required this.hari,
    required this.totalJam,
    required this.totalGuru,
    required this.totalKelas,
  });

  final String hari;
  final int totalJam;
  final int totalGuru;
  final int totalKelas;

  factory RekapHariModel.fromJson(Map<String, dynamic> json) {
    return RekapHariModel(
      hari: json['hari']?.toString() ?? '-',
      totalJam: int.tryParse(json['total_jam']?.toString() ?? '0') ?? 0,
      totalGuru: int.tryParse(json['total_guru']?.toString() ?? '0') ?? 0,
      totalKelas: int.tryParse(json['total_kelas']?.toString() ?? '0') ?? 0,
    );
  }
}

// ─── MODEL: Laporan Ringkas ───────────────────────────────────────────────────
class LaporanRingkasModel {
  const LaporanRingkasModel({
    required this.totalJamJadwal,
    required this.totalGuruJadwal,
    required this.totalKelasJadwal,
    required this.totalKelas,
    required this.totalGuru,
    required this.totalPerangkat,
    required this.perangkatLengkap,
    required this.totalParenting,
  });

  final int totalJamJadwal;
  final int totalGuruJadwal;
  final int totalKelasJadwal;
  final int totalKelas;
  final int totalGuru;
  final int totalPerangkat;
  final int perangkatLengkap;
  final int totalParenting;

  int get perangkatBelumLengkap => totalPerangkat - perangkatLengkap;
  double get persentasePerangkat =>
      totalPerangkat == 0 ? 0 : perangkatLengkap / totalPerangkat;

  factory LaporanRingkasModel.fromJson(Map<String, dynamic> json) {
    final jadwal = json['jadwal'] as Map<String, dynamic>? ?? {};
    final kelas = json['kelas'] as Map<String, dynamic>? ?? {};
    final guru = json['guru'] as Map<String, dynamic>? ?? {};
    final perangkat = json['perangkat'] as Map<String, dynamic>? ?? {};
    final parenting = json['parenting'] as Map<String, dynamic>? ?? {};

    return LaporanRingkasModel(
      totalJamJadwal: int.tryParse(jadwal['total_jam']?.toString() ?? '0') ?? 0,
      totalGuruJadwal:
          int.tryParse(jadwal['total_guru']?.toString() ?? '0') ?? 0,
      totalKelasJadwal:
          int.tryParse(jadwal['total_kelas']?.toString() ?? '0') ?? 0,
      totalKelas: int.tryParse(kelas['total']?.toString() ?? '0') ?? 0,
      totalGuru: int.tryParse(guru['total']?.toString() ?? '0') ?? 0,
      totalPerangkat:
          int.tryParse(perangkat['total']?.toString() ?? '0') ?? 0,
      perangkatLengkap:
          int.tryParse(perangkat['lengkap']?.toString() ?? '0') ?? 0,
      totalParenting:
          int.tryParse(parenting['total']?.toString() ?? '0') ?? 0,
    );
  }
}
