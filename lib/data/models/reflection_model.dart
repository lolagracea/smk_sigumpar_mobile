import 'package:equatable/equatable.dart';

class ReflectionModel extends Equatable {
  final String id;
  final String? kelasId;
  final DateTime tanggal;
  final String? capaian;
  final String? tantangan;
  final String? rencana;

  const ReflectionModel({
    required this.id,
    this.kelasId,
    required this.tanggal,
    this.capaian,
    this.tantangan,
    this.rencana,
  });

  factory ReflectionModel.fromJson(Map<String, dynamic> json) {
    return ReflectionModel(
      id: json['id']?.toString() ?? '',
      kelasId: json['kelas_id']?.toString(),
      tanggal: DateTime.tryParse(json['tanggal'] ?? json['date'] ?? '') ?? DateTime.now(),
      capaian: json['capaian'] ?? json['student_development'],
      tantangan: json['tantangan'] ?? json['class_problem'],
      rencana: json['rencana'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kelas_id': kelasId,
        'tanggal': tanggal.toIso8601String(),
        'capaian': capaian,
        'tantangan': tantangan,
        'rencana': rencana,
      };

  @override
  List<Object?> get props => [id, kelasId, tanggal, capaian, tantangan, rencana];
}
