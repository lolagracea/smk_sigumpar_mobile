import 'package:equatable/equatable.dart';

class SubjectModel extends Equatable {
  final String id;
  final String namaMapel;
  final String kelasId;
  final String namaKelas;
  final String? tingkat;
  final String guruMapelId;
  final String guruMapelNama;
  final String? createdAt;
  final String? updatedAt;

  const SubjectModel({
    required this.id,
    required this.namaMapel,
    required this.kelasId,
    required this.namaKelas,
    this.tingkat,
    required this.guruMapelId,
    required this.guruMapelNama,
    this.createdAt,
    this.updatedAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id']?.toString() ?? '',
      namaMapel: json['nama_mapel']?.toString() ??
          json['mata_pelajaran']?.toString() ??
          '',
      kelasId: json['kelas_id']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? '',
      tingkat: json['tingkat']?.toString(),
      guruMapelId: json['guru_mapel_id']?.toString() ??
          json['guru_id']?.toString() ??
          '',
      guruMapelNama: json['guru_mapel_nama']?.toString() ??
          json['guru_nama']?.toString() ??
          json['nama_guru']?.toString() ??
          '',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_mapel': namaMapel,
      'kelas_id': kelasId,
      'nama_kelas': namaKelas,
      'tingkat': tingkat,
      'guru_mapel_id': guruMapelId,
      'guru_mapel_nama': guruMapelNama,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get kelasLabel {
    final parts = [
      if ((tingkat ?? '').isNotEmpty) tingkat!,
      if (namaKelas.isNotEmpty) namaKelas,
    ];

    return parts.join(' - ');
  }

  @override
  List<Object?> get props => [
    id,
    namaMapel,
    kelasId,
    namaKelas,
    tingkat,
    guruMapelId,
    guruMapelNama,
    createdAt,
    updatedAt,
  ];
}