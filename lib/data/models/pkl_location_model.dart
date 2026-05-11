import 'package:equatable/equatable.dart';

class PklLocationModel extends Equatable {
  final String id;
  final String siswaId;
  final String namaSiswa;
  final String kelasId;
  final String namaKelas;
  final String namaPerusahaan;
  final String alamatPerusahaan;
  final String? posisiSiswa;
  final String? pembimbingIndustri;
  final String? kontakPembimbing;
  final String? tanggalMulai;
  final String? tanggalSelesai;
  final String? deskripsi;
  final String? foto;
  final String createdAt;

  const PklLocationModel({
    required this.id,
    required this.siswaId,
    required this.namaSiswa,
    required this.kelasId,
    required this.namaKelas,
    required this.namaPerusahaan,
    required this.alamatPerusahaan,
    this.posisiSiswa,
    this.pembimbingIndustri,
    this.kontakPembimbing,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.deskripsi,
    this.foto,
    required this.createdAt,
  });

  factory PklLocationModel.fromJson(Map<String, dynamic> json) {
    return PklLocationModel(
      id: json['id']?.toString() ?? '',
      siswaId: json['siswa_id']?.toString() ?? '',
      namaSiswa: json['nama_siswa']?.toString() ?? '',
      kelasId: json['kelas_id']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? '',
      namaPerusahaan: json['nama_perusahaan']?.toString() ?? '',
      alamatPerusahaan: json['alamat_perusahaan']?.toString() ?? '',
      posisiSiswa: json['posisi_siswa']?.toString(),
      pembimbingIndustri: json['pembimbing_industri']?.toString(),
      kontakPembimbing: json['kontak_pembimbing']?.toString(),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      tanggalSelesai: json['tanggal_selesai']?.toString(),
      deskripsi: json['deskripsi']?.toString(),
      foto: json['foto']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'siswa_id': siswaId,
      'nama_siswa': namaSiswa,
      'kelas_id': kelasId,
      'nama_kelas': namaKelas,
      'nama_perusahaan': namaPerusahaan,
      'alamat_perusahaan': alamatPerusahaan,
      'posisi_siswa': posisiSiswa,
      'pembimbing_industri': pembimbingIndustri,
      'kontak_pembimbing': kontakPembimbing,
      'tanggal_mulai': tanggalMulai,
      'tanggal_selesai': tanggalSelesai,
      'deskripsi': deskripsi,
      'foto': foto,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        siswaId,
        namaSiswa,
        kelasId,
        namaKelas,
        namaPerusahaan,
        alamatPerusahaan,
        posisiSiswa,
        pembimbingIndustri,
        kontakPembimbing,
        tanggalMulai,
        tanggalSelesai,
        deskripsi,
        foto,
        createdAt,
      ];
}
