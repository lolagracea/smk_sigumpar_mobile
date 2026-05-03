// lib/features/guru_mapel/perangkat/data/perangkat_model.dart
class PerangkatModel {
  final int?     id;
  final String   namaDokumen;
  final String   jenisDokumen;
  final String?  fileName;
  final String?  fileMime;
  final int      versi;
  final String   statusReview;
  final String?  catatanReview;
  final DateTime? createdAt;

  const PerangkatModel({
    this.id,
    required this.namaDokumen,
    required this.jenisDokumen,
    this.fileName,
    this.fileMime,
    this.versi        = 1,
    this.statusReview = 'menunggu',
    this.catatanReview,
    this.createdAt,
  });

  factory PerangkatModel.fromJson(Map<String, dynamic> json) => PerangkatModel(
    id: json['id'] == null ? null
        : int.tryParse(json['id'].toString()),
    namaDokumen   : json['nama_dokumen']?.toString() ?? '',
    jenisDokumen  : json['jenis_dokumen']?.toString() ?? 'RPP',
    fileName      : json['file_name']?.toString(),
    fileMime      : json['file_mime']?.toString(),
    versi         : (json['versi'] as num?)?.toInt() ?? 1,
    statusReview  : json['status_review']?.toString() ?? 'menunggu',
    catatanReview : json['catatan_review']?.toString(),
    createdAt     : json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString()) : null,
  );
}
