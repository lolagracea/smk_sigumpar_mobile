class Perangkat {
  final String namaDokumen;
  final String status;

  Perangkat({
    required this.namaDokumen,
    required this.status,
  });

  factory Perangkat.fromJson(Map<String, dynamic> json) {
    return Perangkat(
      namaDokumen: json['nama_dokumen'] ?? '-',
      status: json['status_review'] ?? 'menunggu',
    );
  }
}