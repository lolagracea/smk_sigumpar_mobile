import 'package:equatable/equatable.dart';

class ParentingNoteModel extends Equatable {
  final String id;
  final String title;
  final String type;
  final DateTime date;
  final String? summary;
  final String? percentage;
  final String? filePath;

  const ParentingNoteModel({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.summary,
    this.percentage,
    this.filePath,
  });

  factory ParentingNoteModel.fromJson(Map<String, dynamic> json) {
    return ParentingNoteModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      summary: json['summary'] ?? json['catatan'],
      percentage: json['percentage']?.toString() ?? json['presentase']?.toString(),
      filePath: json['file_path'] ?? json['file'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'date': date.toIso8601String(),
        'summary': summary,
        'percentage': percentage,
        'file_path': filePath,
      };

  @override
  List<Object?> get props => [id, title, type, date, summary, percentage, filePath];
}
