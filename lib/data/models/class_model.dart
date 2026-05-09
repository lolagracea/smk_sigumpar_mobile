import 'package:equatable/equatable.dart';

class ClassModel extends Equatable {
  final String id;
  final String namaKelas;
  final String tingkat;
  final String? waliKelasId;
  final String? waliKelasNama;

  const ClassModel({
    required this.id,
    required this.namaKelas,
    required this.tingkat,
    this.waliKelasId,
    this.waliKelasNama,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? '',
      tingkat: json['tingkat']?.toString() ?? '',
      waliKelasId: json['wali_kelas_id']?.toString(),
      waliKelasNama: json['wali_kelas_nama']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_kelas': namaKelas,
      'tingkat': tingkat,
      'wali_kelas_id': waliKelasId,
      'wali_kelas_nama': waliKelasNama,
    };
  }

  @override
  List<Object?> get props => [
    id,
    namaKelas,
    tingkat,
    waliKelasId,
    waliKelasNama,
  ];
}