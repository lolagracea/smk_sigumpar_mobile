import 'package:equatable/equatable.dart';

class ParentingNoteModel extends Equatable {
  final String id;
  final String? siswaId;
  final String? kelasId;
  final DateTime tanggal;
  final int kehadiranOrtu;
  final String? agenda;
  final String? ringkasan;
  final String? catatan;
  final String? dokumentasi;
  final String? fotoUrl;

  const ParentingNoteModel({
    required this.id,
    this.siswaId,
    this.kelasId,
    required this.tanggal,
    this.kehadiranOrtu = 0,
    this.agenda,
    this.ringkasan,
    this.catatan,
    this.dokumentasi,
    this.fotoUrl,
  });

  factory ParentingNoteModel.fromJson(Map<String, dynamic> json) {
    return ParentingNoteModel(
      id: json['id']?.toString() ?? '',
      siswaId: json['siswa_id']?.toString(),
      kelasId: json['kelas_id']?.toString(),
      tanggal: DateTime.tryParse(json['tanggal'] ?? json['date'] ?? '') ?? DateTime.now(),
      kehadiranOrtu: json['kehadiran_ortu'] is int ? json['kehadiran_ortu'] : int.tryParse(json['kehadiran_ortu']?.toString() ?? '0') ?? 0,
      agenda: json['agenda'],
      ringkasan: json['ringkasan'],
      catatan: json['catatan'],
      dokumentasi: json['dokumentasi'],
      fotoUrl: json['foto_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'siswa_id': siswaId,
        'kelas_id': kelasId,
        'tanggal': tanggal.toIso8601String(),
        'kehadiran_ortu': kehadiranOrtu,
        'agenda': agenda,
        'ringkasan': ringkasan,
        'catatan': catatan,
        'dokumentasi': dokumentasi,
        'foto_url': fotoUrl,
      };

  @override
  List<Object?> get props => [id, siswaId, kelasId, tanggal, agenda, ringkasan];
}
