import 'package:equatable/equatable.dart';

class ReflectionModel extends Equatable {
  final String id;
  final String title;
  final DateTime date;
  final String? studentDevelopment;
  final String? classProblem;

  const ReflectionModel({
    required this.id,
    required this.title,
    required this.date,
    this.studentDevelopment,
    this.classProblem,
  });

  factory ReflectionModel.fromJson(Map<String, dynamic> json) {
    return ReflectionModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['judul'] ?? '',
      date: DateTime.tryParse(json['date'] ?? json['tanggal'] ?? '') ?? DateTime.now(),
      studentDevelopment: json['student_development'] ?? json['perkembangan_siswa'],
      classProblem: json['class_problem'] ?? json['masalah_kelas'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'student_development': studentDevelopment,
        'class_problem': classProblem,
      };

  @override
  List<Object?> get props => [id, title, date, studentDevelopment, classProblem];
}
