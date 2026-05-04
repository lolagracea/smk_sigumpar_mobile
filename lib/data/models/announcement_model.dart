import 'package:equatable/equatable.dart';

/// Model untuk Pengumuman/Announcement
///
/// Sesuai dengan backend academic-service Pengumuman model:
/// {
///   id: INTEGER,
///   judul: STRING,
///   isi: TEXT,
///   created_at: DATE,
///   updated_at: DATE,
/// }
class AnnouncementModel extends Equatable {
  final int id;
  final String judul;
  final String isi;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? createdByName;

  const AnnouncementModel({
    required this.id,
    required this.judul,
    required this.isi,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.createdByName,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      judul: json['judul']?.toString() ?? '(Tanpa judul)',
      isi: json['isi']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      createdBy: json['created_by']?.toString(),
      createdByName: json['created_by_name']?.toString() ??
          json['nama_pembuat']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'judul': judul,
    'isi': isi,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (createdByName != null) 'created_by_name': createdByName,
  };

  /// Get short preview dari isi (untuk list)
  String get preview {
    if (isi.length <= 100) return isi;
    return '${isi.substring(0, 100)}...';
  }

  @override
  List<Object?> get props => [id, judul, isi, createdAt, updatedAt];
}