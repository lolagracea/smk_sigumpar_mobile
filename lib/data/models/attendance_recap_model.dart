import 'package:equatable/equatable.dart';

class AttendanceRecapModel {
  final String studentId;
  final String studentName;
  final String nisn;
  final int hadir;
  final int sakit;
  final int izin;
  final int alpa;

  AttendanceRecapModel({
    required this.studentId,
    required this.studentName,
    required this.nisn,
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpa,
  });

  factory AttendanceRecapModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecapModel(
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? '',
      nisn: json['nisn'] ?? '',
      hadir: json['hadir'] ?? 0,
      sakit: json['sakit'] ?? 0,
      izin: json['izin'] ?? 0,
      alpa: json['alpa'] ?? 0,
    );
  }
}