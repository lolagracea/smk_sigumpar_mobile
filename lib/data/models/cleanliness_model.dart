import 'package:equatable/equatable.dart';

class CleanlinessModel extends Equatable {
  final String id;
  final String? kelasId;
  final DateTime tanggal;
  final Map<String, dynamic> penilaian;
  final String? catatan;
  final String? fotoUrl;

  const CleanlinessModel({
    required this.id,
    this.kelasId,
    required this.tanggal,
    this.penilaian = const {},
    this.catatan,
    this.fotoUrl,
  });

  factory CleanlinessModel.fromJson(Map<String, dynamic> json) {
    return CleanlinessModel(
      id: json['id']?.toString() ?? '',
      kelasId: json['kelas_id']?.toString(),
      tanggal: DateTime.tryParse(json['tanggal'] ?? json['date'] ?? '') ?? DateTime.now(),
      penilaian: json['penilaian'] is Map ? Map<String, dynamic>.from(json['penilaian']) : {},
      catatan: json['catatan'] ?? json['summary'],
      fotoUrl: json['foto_url'] ?? json['file_path'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kelas_id': kelasId,
        'tanggal': tanggal.toIso8601String(),
        'penilaian': penilaian,
        'catatan': catatan,
        'foto_url': fotoUrl,
      };

  @override
  List<Object?> get props => [id, kelasId, tanggal, penilaian, catatan, fotoUrl];
}
