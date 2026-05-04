class ArsipSuratModel {
  const ArsipSuratModel({
    required this.id,
    required this.nomor,
    required this.perihal,
    required this.fileName,
    required this.tanggal,
  });

  final int id;
  final String nomor;
  final String perihal;
  final String fileName;
  final DateTime tanggal;
}
