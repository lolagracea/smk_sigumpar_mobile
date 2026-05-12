import 'package:equatable/equatable.dart';

class AttendanceSummaryModel extends Equatable {
  final String studentId;
  final String studentName;
  final String? nisn;
  final int present;
  final int sick;
  final int permission;
  final int absent;
  final int late;

  const AttendanceSummaryModel({
    required this.studentId,
    required this.studentName,
    this.nisn,
    required this.present,
    required this.sick,
    required this.permission,
    required this.absent,
    required this.late,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      studentId: (json['siswa_id'] ?? json['student_id'] ?? json['id'])?.toString() ?? '',
      studentName: json['nama_lengkap'] ?? json['nama_siswa'] ?? json['student_name'] ?? '',
      nisn: json['nisn']?.toString(),
      present: int.tryParse(json['hadir']?.toString() ?? '0') ?? int.tryParse(json['present']?.toString() ?? '0') ?? 0,
      sick: int.tryParse(json['sakit']?.toString() ?? '0') ?? int.tryParse(json['sick']?.toString() ?? '0') ?? 0,
      permission: int.tryParse(json['izin']?.toString() ?? '0') ?? int.tryParse(json['permission']?.toString() ?? '0') ?? 0,
      absent: int.tryParse(json['alpa']?.toString() ?? '0') ?? int.tryParse(json['absent']?.toString() ?? '0') ?? 0,
      late: int.tryParse(json['terlambat']?.toString() ?? '0') ?? int.tryParse(json['late']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  List<Object?> get props => [studentId, studentName, present, sick, permission, absent, late];
}
