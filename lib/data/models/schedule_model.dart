import 'package:equatable/equatable.dart';

class ScheduleModel extends Equatable {
  final String id;
  final String? guruId;
  final String? guruNama;
  final String? kelasId;
  final String? mapelId;
  final String mataPelajaran;
  final String hari;
  final String waktuMulai;
  final String waktuBerakhir;
  final String? namaKelas;
  final String? tingkat;
  final String? namaMapel;

  const ScheduleModel({
    required this.id,
    this.guruId,
    this.guruNama,
    this.kelasId,
    this.mapelId,
    required this.mataPelajaran,
    required this.hari,
    required this.waktuMulai,
    required this.waktuBerakhir,
    this.namaKelas,
    this.tingkat,
    this.namaMapel,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id']?.toString() ?? '',
      guruId: json['guru_id']?.toString(),
      guruNama: json['guru_nama']?.toString() ??
          json['nama_guru']?.toString(),
      kelasId: json['kelas_id']?.toString(),
      mapelId: json['mapel_id']?.toString(),
      mataPelajaran: json['mata_pelajaran']?.toString() ??
          json['nama_mapel']?.toString() ??
          '',
      hari: json['hari']?.toString() ?? '',
      waktuMulai: _formatTime(json['waktu_mulai']?.toString()),
      waktuBerakhir: _formatTime(json['waktu_berakhir']?.toString()),
      namaKelas: json['nama_kelas']?.toString(),
      tingkat: json['tingkat']?.toString(),
      namaMapel: json['nama_mapel']?.toString(),
    );
  }

  static String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '';

    if (value.length >= 5) {
      return value.substring(0, 5);
    }

    return value;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guru_id': guruId,
      'guru_nama': guruNama,
      'kelas_id': kelasId,
      'mapel_id': mapelId,
      'mata_pelajaran': mataPelajaran,
      'hari': hari,
      'waktu_mulai': waktuMulai,
      'waktu_berakhir': waktuBerakhir,
      'nama_kelas': namaKelas,
      'tingkat': tingkat,
      'nama_mapel': namaMapel,
    };
  }

  @override
  List<Object?> get props => [
    id,
    guruId,
    guruNama,
    kelasId,
    mapelId,
    mataPelajaran,
    hari,
    waktuMulai,
    waktuBerakhir,
    namaKelas,
    tingkat,
    namaMapel,
  ];
}