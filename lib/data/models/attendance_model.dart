import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, sick, permission, absent }

extension AttendanceStatusExt on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present: return 'Hadir';
      case AttendanceStatus.sick: return 'Sakit';
      case AttendanceStatus.permission: return 'Izin';
      case AttendanceStatus.absent: return 'Alfa';
    }
  }

  String get code {
    switch (this) {
      case AttendanceStatus.present: return 'H';
      case AttendanceStatus.sick: return 'S';
      case AttendanceStatus.permission: return 'I';
      case AttendanceStatus.absent: return 'A';
    }
  }
}

class AttendanceModel extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String classId;
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.date,
    required this.status,
    this.notes,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name'] ?? json['student']?['name'] ?? '',
      classId: json['class_id']?.toString() ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      status: _statusFromString(json['status']),
      notes: json['notes'],
    );
  }

  static AttendanceStatus _statusFromString(String? s) {
    switch (s) {
      case 'present': return AttendanceStatus.present;
      case 'sick': return AttendanceStatus.sick;
      case 'permission': return AttendanceStatus.permission;
      case 'absent': return AttendanceStatus.absent;
      default: return AttendanceStatus.absent;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'student_name': studentName,
        'class_id': classId,
        'date': date.toIso8601String(),
        'status': status.name,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, studentId, date, status];
}
