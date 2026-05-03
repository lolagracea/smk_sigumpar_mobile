// lib/features/absensi_siswa/data/models/absensi_siswa_model.dart
import '../../../../../shared/models/shared_models.dart';

class AbsensiSiswaModel {
  final int? id;
  final int siswaId;
  final String? nis;
  final String? namaSiswa;
  final int? kelasId;
  final int? mapelId;
  final String tanggal;
  final String status;
  final String? keterangan;

  const AbsensiSiswaModel({
    this.id,
    required this.siswaId,
    this.nis,
    this.namaSiswa,
    this.kelasId,
    this.mapelId,
    required this.tanggal,
    required this.status,
    this.keterangan,
  });

  factory AbsensiSiswaModel.fromJson(Map<String, dynamic> json) {
    return AbsensiSiswaModel(
      id: json['id'] as int?,
      siswaId: (json['siswa_id'] ?? json['id_siswa'] ?? 0) as int,
      nis: json['nis']?.toString(),
      namaSiswa: json['nama_siswa']?.toString() ?? json['namasiswa']?.toString(),
      kelasId: json['kelas_id'] as int?,
      mapelId: json['mapel_id'] as int?,
      tanggal: json['tanggal']?.toString() ?? '',
      status: json['status']?.toString() ?? 'hadir',
      keterangan: json['keterangan']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'siswa_id': siswaId,
        if (kelasId != null) 'kelas_id': kelasId,
        if (mapelId != null) 'mapel_id': mapelId,
        'tanggal': tanggal,
        'status': status,
        if (keterangan != null) 'keterangan': keterangan,
      };

  AbsensiSiswaModel copyWith({String? status, String? keterangan}) {
    return AbsensiSiswaModel(
      id: id,
      siswaId: siswaId,
      nis: nis,
      namaSiswa: namaSiswa,
      kelasId: kelasId,
      mapelId: mapelId,
      tanggal: tanggal,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
    );
  }
}

// Bulk save request
class AbsensiBulkRequest {
  final List<AbsensiSiswaModel> items;

  const AbsensiBulkRequest(this.items);

  Map<String, dynamic> toJson() => {
        'data': items.map((e) => e.toJson()).toList(),
      };
}
