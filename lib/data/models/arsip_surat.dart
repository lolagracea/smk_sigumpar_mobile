class ArsipSurat {
  const ArsipSurat({
    required this.id,
    required this.nomorSurat,
    required this.perihal,
    this.fileUrl,
  });

  final int id;
  final String nomorSurat;
  final String perihal;
  final String? fileUrl;
}
