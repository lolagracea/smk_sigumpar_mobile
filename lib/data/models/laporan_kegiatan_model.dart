// ─────────────────────────────────────────────────────────────────────────────
// lib/data/models/laporan_kegiatan_model.dart
//
// Model data Laporan Kegiatan Pramuka — mirror web response dari backend:
// SELECT id, judul, deskripsi, tanggal, file_nama, file_mime,
//        created_by, created_at, updated_at FROM laporan_kegiatan
// ─────────────────────────────────────────────────────────────────────────────

class LaporanKegiatanModel {
  final int id;
  final String judul;
  final String? deskripsi;
  final String tanggal;
  final String? fileNama;  // nama file asli (mis: laporan.pdf)
  final String? fileMime;  // MIME type (mis: application/pdf, image/jpeg)
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  const LaporanKegiatanModel({
    required this.id,
    required this.judul,
    this.deskripsi,
    required this.tanggal,
    this.fileNama,
    this.fileMime,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory LaporanKegiatanModel.fromJson(Map<String, dynamic> json) {
    return LaporanKegiatanModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      judul: json['judul']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString(),
      tanggal: (json['tanggal'] ?? '').toString().length >= 10
          ? json['tanggal'].toString().substring(0, 10)
          : json['tanggal']?.toString() ?? '',
      fileNama: json['file_nama']?.toString(),
      fileMime: json['file_mime']?.toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'judul': judul,
        'deskripsi': deskripsi,
        'tanggal': tanggal,
        'file_nama': fileNama,
        'file_mime': fileMime,
        'created_by': createdBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// Cek apakah laporan memiliki file terlampir
  bool get hasFile => fileNama != null && fileNama!.isNotEmpty;

  /// Cek apakah file adalah gambar — mirror web isImageMime()
  bool get isImage {
    if (fileMime == null) return false;
    return fileMime!.startsWith('image/');
  }

  /// Cek apakah file adalah PDF — mirror web isPdfMime()
  bool get isPdf => fileMime == 'application/pdf';
}