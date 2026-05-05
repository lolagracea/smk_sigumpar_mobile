class AttendanceModel {
  final String id; // student_id
  final String studentName;
  final String nisn;
  final int hadir;
  final int sakit;
  final int izin;
  final int alpa;

  AttendanceModel({
    required this.id,
    required this.studentName,
    required this.nisn,
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpa,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString() ?? json['student_id']?.toString() ?? '',
      studentName: json['nama_lengkap'] ?? json['student_name'] ?? 'Tanpa Nama',
      nisn: json['nisn'] ?? '-',
      hadir: json['hadir'] ?? 0,
      sakit: json['sakit'] ?? 0,
      izin: json['izin'] ?? 0,
      alpa: json['alpa'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_name': studentName,
      'nisn': nisn,
      'hadir': hadir,
      'sakit': sakit,
      'izin': izin,
      'alpa': alpa,
    };
  }
}