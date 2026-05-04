import 'package:equatable/equatable.dart';

class CleanlinessModel extends Equatable {
  final String id;
  final String title;
  final DateTime date;
  final String? summary;
  final String? filePath;

  const CleanlinessModel({
    required this.id,
    required this.title,
    required this.date,
    this.summary,
    this.filePath,
  });

  factory CleanlinessModel.fromJson(Map<String, dynamic> json) {
    return CleanlinessModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['judul'] ?? '',
      date: DateTime.tryParse(json['date'] ?? json['tanggal'] ?? '') ?? DateTime.now(),
      summary: json['summary'] ?? json['catatan'],
      filePath: json['file_path'] ?? json['file'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'summary': summary,
        'file_path': filePath,
      };

  @override
  List<Object?> get props => [id, title, date, summary, filePath];
}
