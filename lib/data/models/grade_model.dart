import 'package:equatable/equatable.dart';

class GradeModel extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String subjectId;
  final String subjectName;
  final double dailyScore;
  final double midScore;
  final double finalScore;
  final double? practiceScore;
  final double average;
  final String semester;
  final String academicYear;
  final String? notes;

  const GradeModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subjectId,
    required this.subjectName,
    required this.dailyScore,
    required this.midScore,
    required this.finalScore,
    this.practiceScore,
    required this.average,
    required this.semester,
    required this.academicYear,
    this.notes,
  });

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name'] ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      subjectName: json['subject_name'] ?? '',
      dailyScore: (json['daily_score'] ?? 0).toDouble(),
      midScore: (json['mid_score'] ?? 0).toDouble(),
      finalScore: (json['final_score'] ?? 0).toDouble(),
      practiceScore: json['practice_score']?.toDouble(),
      average: (json['average'] ?? 0).toDouble(),
      semester: json['semester'] ?? '1',
      academicYear: json['academic_year'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'student_name': studentName,
        'subject_id': subjectId,
        'subject_name': subjectName,
        'daily_score': dailyScore,
        'mid_score': midScore,
        'final_score': finalScore,
        'practice_score': practiceScore,
        'average': average,
        'semester': semester,
        'academic_year': academicYear,
        'notes': notes,
      };

  String get letterGrade {
    if (average >= 90) return 'A';
    if (average >= 80) return 'B';
    if (average >= 70) return 'C';
    if (average >= 60) return 'D';
    return 'E';
  }

  @override
  List<Object?> get props => [id, studentId, subjectId, semester, academicYear];
}
