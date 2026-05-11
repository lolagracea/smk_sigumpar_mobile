import 'package:equatable/equatable.dart';

class StudentModel extends Equatable {
  final String id;
  final String nisn;
  final String namaLengkap;
  final String kelasId;
  final String namaKelas;

  const StudentModel({
    required this.id,
    required this.nisn,
    required this.namaLengkap,
    required this.kelasId,
    required this.namaKelas,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id']?.toString() ?? '',
      nisn: json['nisn']?.toString() ?? '',
      namaLengkap: json['nama_lengkap']?.toString() ?? '',
      kelasId: json['kelas_id']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? 'Belum Ada Kelas',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nisn': nisn,
      'nama_lengkap': namaLengkap,
      'kelas_id': kelasId,
      'nama_kelas': namaKelas,
    };
  }

  @override
  List<Object?> get props => [
    id,
    nisn,
    namaLengkap,
    kelasId,
    namaKelas,
  ];
}