import 'package:equatable/equatable.dart';

class ArsipSuratModel extends Equatable {
  final String id;
  final String nomorSurat;
  final String fileUrl;
  final String? createdAt;
  final String? updatedAt;

  const ArsipSuratModel({
    required this.id,
    required this.nomorSurat,
    required this.fileUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory ArsipSuratModel.fromJson(Map<String, dynamic> json) {
    return ArsipSuratModel(
      id: json['id']?.toString() ?? '',
      nomorSurat: json['nomor_surat']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  String get fileName {
    if (fileUrl.isEmpty) return '-';
    return fileUrl.split('/').last;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomor_surat': nomorSurat,
      'file_url': fileUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    nomorSurat,
    fileUrl,
    createdAt,
    updatedAt,
  ];
}