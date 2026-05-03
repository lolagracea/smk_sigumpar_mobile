import 'package:equatable/equatable.dart';

/// Status kehadiran guru
/// Sesuai dengan validasi backend (learning-service/AbsensiGuru.js):
/// status: ['hadir', 'terlambat', 'izin', 'sakit', 'alpa']
enum StatusKehadiran {
  hadir('hadir', 'Hadir'),
  terlambat('terlambat', 'Terlambat'),
  izin('izin', 'Izin'),
  sakit('sakit', 'Sakit'),
  alpa('alpa', 'Alpa');

  final String value;
  final String label;
  const StatusKehadiran(this.value, this.label);

  /// Convert string dari backend ke enum
  static StatusKehadiran fromString(String value) {
    return StatusKehadiran.values.firstWhere(
          (e) => e.value == value.toLowerCase(),
      orElse: () => StatusKehadiran.hadir,
    );
  }

  /// Status yang bisa dipilih user di dropdown
  static List<StatusKehadiran> get selectableStatuses => [
    StatusKehadiran.hadir,
    StatusKehadiran.izin,
    StatusKehadiran.sakit,
    StatusKehadiran.alpa,
  ];
}

class AbsensiGuruModel extends Equatable {
  final int? id;
  final String? idAbsensiGuru;
  final String userId;
  final String namaGuru;
  final String mataPelajaran;
  final String? jamMasuk;
  final DateTime tanggal;
  final String? foto;
  final StatusKehadiran status;
  final String? keterangan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AbsensiGuruModel({
    this.id,
    this.idAbsensiGuru,
    required this.userId,
    required this.namaGuru,
    this.mataPelajaran = '-',
    this.jamMasuk,
    required this.tanggal,
    this.foto,
    required this.status,
    this.keterangan,
    this.createdAt,
    this.updatedAt,
  });

  factory AbsensiGuruModel.fromJson(Map<String, dynamic> json) {
    return AbsensiGuruModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      idAbsensiGuru: json['id_absensiguru']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      namaGuru: json['nama_guru']?.toString() ?? 'Unknown',
      mataPelajaran: json['mata_pelajaran']?.toString() ?? '-',
      jamMasuk: json['jam_masuk']?.toString(),
      tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? '')
          ?? DateTime.now(),
      foto: json['foto']?.toString(),
      status: StatusKehadiran.fromString(
        json['status']?.toString() ?? 'hadir',
      ),
      keterangan: json['keterangan']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (idAbsensiGuru != null) 'id_absensiguru': idAbsensiGuru,
    'user_id': userId,
    'nama_guru': namaGuru,
    'mata_pelajaran': mataPelajaran,
    if (jamMasuk != null) 'jam_masuk': jamMasuk,
    'tanggal': tanggal.toIso8601String().split('T').first,
    if (foto != null) 'foto': foto,
    'status': status.value,
    if (keterangan != null) 'keterangan': keterangan,
  };

  AbsensiGuruModel copyWith({
    int? id,
    String? idAbsensiGuru,
    String? userId,
    String? namaGuru,
    String? mataPelajaran,
    String? jamMasuk,
    DateTime? tanggal,
    String? foto,
    StatusKehadiran? status,
    String? keterangan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AbsensiGuruModel(
      id: id ?? this.id,
      idAbsensiGuru: idAbsensiGuru ?? this.idAbsensiGuru,
      userId: userId ?? this.userId,
      namaGuru: namaGuru ?? this.namaGuru,
      mataPelajaran: mataPelajaran ?? this.mataPelajaran,
      jamMasuk: jamMasuk ?? this.jamMasuk,
      tanggal: tanggal ?? this.tanggal,
      foto: foto ?? this.foto,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    idAbsensiGuru,
    userId,
    namaGuru,
    mataPelajaran,
    jamMasuk,
    tanggal,
    foto,
    status,
    keterangan,
    createdAt,
    updatedAt,
  ];
}