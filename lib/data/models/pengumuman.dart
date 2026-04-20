class Pengumuman {
  const Pengumuman({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tanggal,
  });

  final int id;
  final String judul;
  final String isi;
  final DateTime tanggal;
}
