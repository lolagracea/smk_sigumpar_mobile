class ApiConstants {
  static const String baseUrl = 'http://localhost:8001';

  static const String authBase = '/api/auth';
  static const String academicBase = '/api/academic';

  static const String login = '$authBase/login';
  static const String usersSearch = '$authBase/users/search';

  static const String kelas = '$academicBase/kelas';
  static const String siswa = '$academicBase/siswa';
  static const String pengumuman = '$academicBase/pengumuman';
  static const String arsipSurat = '$academicBase/arsip-surat';
  static const String guru = '$academicBase/guru';
  static const String mapel = '$academicBase/mapel';
  static const String jadwal = '$academicBase/jadwal';
  static const String piket = '$academicBase/piket';
  static const String upacara = '$academicBase/upacara';
}
