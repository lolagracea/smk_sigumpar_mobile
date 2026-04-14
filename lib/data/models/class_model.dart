import 'package:equatable/equatable.dart';

class ClassModel extends Equatable {
  final String id;
  final String name;
  final String grade;         // X, XI, XII
  final String major;         // Jurusan
  final String? homeroomId;
  final String? homeroomName;
  final int studentCount;
  final bool isActive;

  const ClassModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.major,
    this.homeroomId,
    this.homeroomName,
    this.studentCount = 0,
    this.isActive = true,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      grade: json['grade'] ?? '',
      major: json['major'] ?? '',
      homeroomId: json['homeroom_id']?.toString(),
      homeroomName: json['homeroom_name'] ?? json['homeroom']?['name'],
      studentCount: json['student_count'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'major': major,
        'homeroom_id': homeroomId,
        'homeroom_name': homeroomName,
        'student_count': studentCount,
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [id, name, grade, major, isActive];
}
