import 'package:equatable/equatable.dart';

class SubjectModel extends Equatable {
  final String id;
  final String namaMapel;
  final String? kodeMapel;
  final String? guruId;
  final String? guruNama;

  const SubjectModel({
    required this.id,
    required this.namaMapel,
    this.kodeMapel,
    this.guruId,
    this.guruNama,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id']?.toString() ?? '',
      namaMapel: json['nama_mapel']?.toString() ?? '',
      kodeMapel: json['kode_mapel']?.toString(),
      guruId: json['guru_id']?.toString(),
      guruNama: json['guru_nama']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_mapel': namaMapel,
      'kode_mapel': kodeMapel,
      'guru_id': guruId,
      'guru_nama': guruNama,
    };
  }

  @override
  List<Object?> get props => [
        id,
        namaMapel,
        kodeMapel,
        guruId,
        guruNama,
      ];
}
