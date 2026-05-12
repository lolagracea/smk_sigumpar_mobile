import 'package:equatable/equatable.dart';

class SummonsLetterModel extends Equatable {
  final String id;
  final String? siswaId;
  final String? kelasId;
  final DateTime tanggal;
  final String? alasan;
  final String? tindakLanjut;
  final String status;

  const SummonsLetterModel({
    required this.id,
    this.siswaId,
    this.kelasId,
    required this.tanggal,
    this.alasan,
    this.tindakLanjut,
    required this.status,
  });

  factory SummonsLetterModel.fromJson(Map<String, dynamic> json) {
    return SummonsLetterModel(
      id: json['id']?.toString() ?? '',
      siswaId: json['siswa_id']?.toString(),
      kelasId: json['kelas_id']?.toString(),
      tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
      alasan: json['alasan'],
      tindakLanjut: json['tindak_lanjut'],
      status: json['status'] ?? 'draft',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'siswa_id': siswaId,
        'kelas_id': kelasId,
        'tanggal': tanggal.toIso8601String(),
        'alasan': alasan,
        'tindak_lanjut': tindakLanjut,
        'status': status,
      };

  @override
  List<Object?> get props => [id, siswaId, kelasId, tanggal, status];
}
