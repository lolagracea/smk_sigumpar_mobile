import 'package:equatable/equatable.dart';

class PklProgressModel extends Equatable {
  final String id;
  final String siswaId;
  final String namaSiswa;
  final String kelasId;
  final String namaKelas;
  final String pklLokasiId;
  final String judulKegiatan;
  final String deskripsiKegiatan;
  final String tanggalKegiatan;
  final int mingguKe;
  final String? jamMulai;
  final String? jamSelesai;
  final String? buktiFoto;
  final String? capaian;
  final String? penilaian;
  final String? kendala;
  final String createdAt;

  const PklProgressModel({
    required this.id,
    required this.siswaId,
    required this.namaSiswa,
    required this.kelasId,
    required this.namaKelas,
    required this.pklLokasiId,
    required this.judulKegiatan,
    required this.deskripsiKegiatan,
    required this.tanggalKegiatan,
    required this.mingguKe,
    this.jamMulai,
    this.jamSelesai,
    this.buktiFoto,
    this.capaian,
    this.penilaian,
    this.kendala,
    required this.createdAt,
  });

  factory PklProgressModel.fromJson(Map<String, dynamic> json) {
    return PklProgressModel(
      id: json['id']?.toString() ?? '',
      siswaId: json['siswa_id']?.toString() ?? '',
      namaSiswa: json['nama_siswa']?.toString() ?? '',
      kelasId: json['kelas_id']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? '',
      pklLokasiId: json['pkl_lokasi_id']?.toString() ?? '',
      judulKegiatan: json['judul_kegiatan']?.toString() ?? '',
      deskripsiKegiatan: json['deskripsi_kegiatan']?.toString() ?? '',
      tanggalKegiatan: json['tanggal_kegiatan']?.toString() ?? '',
      mingguKe: json['minggu_ke'] is int
          ? json['minggu_ke']
          : int.tryParse(json['minggu_ke']?.toString() ?? '') ?? 1,
      jamMulai: json['jam_mulai']?.toString(),
      jamSelesai: json['jam_selesai']?.toString(),
      buktiFoto: json['bukti_foto']?.toString(),
      capaian: json['capaian']?.toString(),
      penilaian: json['penilaian']?.toString(),
      kendala: json['kendala']?.toString(),
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
      'pkl_lokasi_id': pklLokasiId,
      'judul_kegiatan': judulKegiatan,
      'deskripsi_kegiatan': deskripsiKegiatan,
      'tanggal_kegiatan': tanggalKegiatan,
      'minggu_ke': mingguKe,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'bukti_foto': buktiFoto,
      'capaian': capaian,
      'penilaian': penilaian,
      'kendala': kendala,
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
        pklLokasiId,
        judulKegiatan,
        deskripsiKegiatan,
        tanggalKegiatan,
        mingguKe,
        jamMulai,
        jamSelesai,
        buktiFoto,
        capaian,
        penilaian,
        kendala,
        createdAt,
      ];
}
