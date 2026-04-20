class Kelas {
  const Kelas({
    required this.id,
    required this.nama,
    required this.tingkat,
    this.waliKelas,
  });

  final int id;
  final String nama;
  final String tingkat;
  final String? waliKelas;
}
