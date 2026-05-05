class CatatanMengajar {
  final String namaGuru;
  final String materi;

  CatatanMengajar({
    required this.namaGuru,
    required this.materi,
  });

  factory CatatanMengajar.fromJson(Map<String, dynamic> json) {
    return CatatanMengajar(
      namaGuru: json['nama_guru'] ?? '-',
      materi: json['materi'] ?? '-',
    );
  }
}