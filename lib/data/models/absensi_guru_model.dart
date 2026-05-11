import 'package:equatable/equatable.dart';

enum StatusKehadiran {
  hadir('hadir', 'Hadir'),
  terlambat('terlambat', 'Terlambat'),
  izin('izin', 'Izin'),
  sakit('sakit', 'Sakit'),
  alpa('alpa', 'Alpa');

  final String value;
  final String label;

  const StatusKehadiran(this.value, this.label);

  static StatusKehadiran fromString(String? value) {
    final normalized = (value ?? 'hadir').toLowerCase();

    return StatusKehadiran.values.firstWhere(
          (e) => e.value == normalized,
      orElse: () => StatusKehadiran.hadir,
    );
  }

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
    final rawId = json['id'];
    final rawTanggal = json['tanggal'];

    return AbsensiGuruModel(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? ''),
      idAbsensiGuru: json['id_absensiGuru']?.toString() ??
          json['id_absensiguru']?.toString() ??
          json['id_absensi_guru']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      namaGuru: json['namaGuru']?.toString() ??
          json['nama_guru']?.toString() ??
          json['nama']?.toString() ??
          json['nama_lengkap']?.toString() ??
          'Unknown',
      mataPelajaran: json['mataPelajaran']?.toString() ??
          json['mata_pelajaran']?.toString() ??
          json['mapel']?.toString() ??
          json['nama_mapel']?.toString() ??
          '-',
      jamMasuk: json['jamMasuk']?.toString() ??
          json['jam_masuk']?.toString() ??
          json['jam_masuk_guru']?.toString(),
      tanggal: DateTime.tryParse(rawTanggal?.toString() ?? '') ??
          DateTime.now(),
      foto: json['foto']?.toString() ??
          json['foto_url']?.toString() ??
          json['fotoAbsensi']?.toString() ??
          json['foto_absensi']?.toString(),
      status: StatusKehadiran.fromString(json['status']?.toString()),
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