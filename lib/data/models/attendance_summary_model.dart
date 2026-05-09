import 'package:equatable/equatable.dart';

class AttendanceSummaryModel extends Equatable {
  final String studentId;
  final String studentName;
  final int present;
  final int sick;
  final int permission;
  final int absent;

  const AttendanceSummaryModel({
    required this.studentId,
    required this.studentName,
    required this.present,
    required this.sick,
    required this.permission,
    required this.absent,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name'] ?? '',
      present: json['present'] ?? json['hadir'] ?? 0,
      sick: json['sick'] ?? json['sakit'] ?? 0,
      permission: json['permission'] ?? json['izin'] ?? 0,
      absent: json['absent'] ?? json['alfa'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [studentId, studentName, present, sick, permission, absent];
}
