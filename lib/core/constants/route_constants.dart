class RouteConstants {
  static const String login = '/login';
  static const String home = '/';
  static const String profile = '/profile';

  // ── Tata Usaha ────────────────────────────────────────────────────────────
  static const String kelas = '/tata-usaha/kelas';
  static const String siswa = '/tata-usaha/siswa';
  static const String pengumuman = '/tata-usaha/pengumuman';
  static const String arsipSurat = '/tata-usaha/arsip-surat';

  // ── Wakil Kepala Sekolah ──────────────────────────────────────────────────
  static const String wakilHome = '/wakil-kepsek';
  static const String wakilPerangkatList = '/wakil-kepsek/perangkat';
  static const String wakilPerangkatDetail = '/wakil-kepsek/perangkat/:guruId';
  static const String wakilJadwal = '/wakil-kepsek/jadwal';
  static const String wakilRekapJadwal = '/wakil-kepsek/jadwal/rekap';
  static const String wakilLaporan = '/wakil-kepsek/laporan';
}
