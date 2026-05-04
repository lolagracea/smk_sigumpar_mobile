import 'package:equatable/equatable.dart';

class MapelAssignmentModel extends Equatable {
  final String mapelId;
  final String namaMapel;
  final String kelasId;
  final String namaKelas;
  final String? tingkat;
  final String? guruMapelId;
  final String? guruMapelNama;

  const MapelAssignmentModel({
    required this.mapelId,
    required this.namaMapel,
    required this.kelasId,
    required this.namaKelas,
    this.tingkat,
    this.guruMapelId,
    this.guruMapelNama,
  });

  factory MapelAssignmentModel.fromJson(Map<String, dynamic> json) {
    return MapelAssignmentModel(
      mapelId: json['mapel_id']?.toString() ??
          json['id']?.toString() ??
          '',
      namaMapel: json['nama_mapel']?.toString() ??
          json['mata_pelajaran']?.toString() ??
          '',
      kelasId: json['kelas_id']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? '',
      tingkat: json['tingkat']?.toString(),
      guruMapelId: json['guru_mapel_id']?.toString(),
      guruMapelNama: json['guru_mapel_nama']?.toString(),
    );
  }

  String get label {
    final kelasLabel = [
      if ((tingkat ?? '').isNotEmpty) tingkat,
      if (namaKelas.isNotEmpty) namaKelas,
    ].join(' - ');

    if (kelasLabel.isEmpty) return namaMapel;

    return '$namaMapel • $kelasLabel';
  }

  @override
  List<Object?> get props => [
    mapelId,
    namaMapel,
    kelasId,
    namaKelas,
    tingkat,
    guruMapelId,
    guruMapelNama,
  ];
}