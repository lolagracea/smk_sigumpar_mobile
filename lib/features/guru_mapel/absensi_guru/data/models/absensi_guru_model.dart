// lib/features/absensi_guru/data/models/absensi_guru_model.dart
class AbsensiGuruModel {
  final int? id;
  final String tanggal;
  final String status;
  final String? keterangan;
  final String? fotoBase64;
  final String? namaGuru;
  final String? userId;
  final DateTime? createdAt;

  const AbsensiGuruModel({
    this.id,
    required this.tanggal,
    required this.status,
    this.keterangan,
    this.fotoBase64,
    this.namaGuru,
    this.userId,
    this.createdAt,
  });

  factory AbsensiGuruModel.fromJson(Map<String, dynamic> json) {
    return AbsensiGuruModel(
      id: json['id'] as int?,
      tanggal: json['tanggal']?.toString() ?? '',
      status: json['status']?.toString() ?? 'hadir',
      keterangan: json['keterangan']?.toString(),
      fotoBase64: json['foto_base64']?.toString() ?? json['foto']?.toString(),
      namaGuru: json['nama_guru']?.toString(),
      userId: json['user_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'tanggal': tanggal,
        'status': status,
        if (keterangan != null) 'keterangan': keterangan,
        if (fotoBase64 != null) 'foto_base64': fotoBase64,
      };

  AbsensiGuruModel copyWith({
    int? id,
    String? tanggal,
    String? status,
    String? keterangan,
    String? fotoBase64,
  }) {
    return AbsensiGuruModel(
      id: id ?? this.id,
      tanggal: tanggal ?? this.tanggal,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
      fotoBase64: fotoBase64 ?? this.fotoBase64,
      namaGuru: namaGuru,
      userId: userId,
      createdAt: createdAt,
    );
  }
}

// ── Summary Model ──────────────────────────────────────────────────────────
class AbsensiSummary {
  final int total;
  final int hadir;
  final int terlambat;
  final int izin;
  final int sakit;
  final int alpa;

  const AbsensiSummary({
    this.total = 0,
    this.hadir = 0,
    this.terlambat = 0,
    this.izin = 0,
    this.sakit = 0,
    this.alpa = 0,
  });

  factory AbsensiSummary.fromList(List<AbsensiGuruModel> list) {
    final summary = AbsensiSummary(
      total: list.length,
      hadir: list.where((e) => e.status == 'hadir').length,
      terlambat: list.where((e) => e.status == 'terlambat').length,
      izin: list.where((e) => e.status == 'izin').length,
      sakit: list.where((e) => e.status == 'sakit').length,
      alpa: list.where((e) => e.status == 'alpa').length,
    );
    return summary;
  }
}
