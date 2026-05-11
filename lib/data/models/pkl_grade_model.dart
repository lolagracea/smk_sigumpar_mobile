import 'package:equatable/equatable.dart';

class PklGradeModel extends Equatable {
  final String id;
  final String siswaId;
  final String namaSiswa;
  final String kelasId;
  final String namaKelas;
  final String? pklLokasiId;
  final String? aspekTeknis;
  final String? aspekNonTeknis;
  final String? aspekKedisiplinan;
  final String? aspekKerjasama;
  final String? aspekInisiatif;
  final String? nilai;
  final String? deskripsi;
  final String createdAt;

  const PklGradeModel({
    required this.id,
    required this.siswaId,
    required this.namaSiswa,
    required this.kelasId,
    required this.namaKelas,
    this.pklLokasiId,
    this.aspekTeknis,
    this.aspekNonTeknis,
    this.aspekKedisiplinan,
    this.aspekKerjasama,
    this.aspekInisiatif,
    this.nilai,
    this.deskripsi,
    required this.createdAt,
  });

  factory PklGradeModel.fromJson(Map<String, dynamic> json) {
    return PklGradeModel(
      id: json['id']?.toString() ?? '',
      siswaId: json['siswa_id']?.toString() ?? '',
      namaSiswa: json['nama_siswa']?.toString() ?? '',
      kelasId: json['kelas_id']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? '',
      pklLokasiId: json['pkl_lokasi_id']?.toString(),
      aspekTeknis: json['aspek_teknis']?.toString(),
      aspekNonTeknis: json['aspek_non_teknis']?.toString(),
      aspekKedisiplinan: json['aspek_kedisiplinan']?.toString(),
      aspekKerjasama: json['aspek_kerjasama']?.toString(),
      aspekInisiatif: json['aspek_inisiatif']?.toString(),
      nilai: json['nilai']?.toString(),
      deskripsi: json['deskripsi']?.toString(),
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
      'aspek_teknis': aspekTeknis,
      'aspek_non_teknis': aspekNonTeknis,
      'aspek_kedisiplinan': aspekKedisiplinan,
      'aspek_kerjasama': aspekKerjasama,
      'aspek_inisiatif': aspekInisiatif,
      'nilai': nilai,
      'deskripsi': deskripsi,
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
        aspekTeknis,
        aspekNonTeknis,
        aspekKedisiplinan,
        aspekKerjasama,
        aspekInisiatif,
        nilai,
        deskripsi,
        createdAt,
      ];
}
