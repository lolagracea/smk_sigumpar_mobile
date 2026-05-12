import 'package:equatable/equatable.dart';

class GradeModel extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String? nisn;
  final String subjectId;
  final double tugas;
  final double kuis;
  final double uts;
  final double uas;
  final double praktik;
  final double nilaiAkhir;
  final String semester;
  final String academicYear;
  final Map<String, int>? summaryAbsensi;

  const GradeModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.nisn,
    required this.subjectId,
    required this.tugas,
    required this.kuis,
    required this.uts,
    required this.uas,
    required this.praktik,
    required this.nilaiAkhir,
    required this.semester,
    required this.academicYear,
    this.summaryAbsensi,
  });

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    // Mapping dari snake_case backend ke camelCase model
    final absensiJson = json['absensi'];
    Map<String, int>? absensi;
    if (absensiJson is Map) {
      absensi = {
        'hadir': int.tryParse(absensiJson['hadir']?.toString() ?? '0') ?? 0,
        'izin': int.tryParse(absensiJson['izin']?.toString() ?? '0') ?? 0,
        'sakit': int.tryParse(absensiJson['sakit']?.toString() ?? '0') ?? 0,
        'alpa': int.tryParse(absensiJson['alpa']?.toString() ?? '0') ?? 0,
        'terlambat': int.tryParse(absensiJson['terlambat']?.toString() ?? '0') ?? 0,
      };
    }

    return GradeModel(
      id: json['id']?.toString() ?? '',
      studentId: json['siswa_id']?.toString() ?? '',
      studentName: json['nama_lengkap'] ?? json['nama_siswa'] ?? '',
      nisn: json['nisn']?.toString(),
      subjectId: json['mapel_id']?.toString() ?? '',
      tugas: double.tryParse(json['tugas']?.toString() ?? '0') ?? 0.0,
      kuis: double.tryParse(json['kuis']?.toString() ?? '0') ?? 0.0,
      uts: double.tryParse(json['uts']?.toString() ?? '0') ?? 0.0,
      uas: double.tryParse(json['uas']?.toString() ?? '0') ?? 0.0,
      praktik: double.tryParse(json['praktik']?.toString() ?? '0') ?? 0.0,
      nilaiAkhir: double.tryParse(json['nilai_akhir']?.toString() ?? '0') ?? 0.0,
      semester: json['semester'] ?? '',
      academicYear: json['tahun_ajar'] ?? '',
      summaryAbsensi: absensi,
    );
  }

  String get letterGrade {
    if (nilaiAkhir >= 90) return 'A';
    if (nilaiAkhir >= 80) return 'B';
    if (nilaiAkhir >= 70) return 'C';
    if (nilaiAkhir >= 60) return 'D';
    return 'E';
  }

  @override
  List<Object?> get props => [id, studentId, subjectId, semester, academicYear];
}
