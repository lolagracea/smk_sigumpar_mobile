class PerangkatModel {
  const PerangkatModel({
    required this.id,
    required this.namaGuru,
    required this.namaDokumen,
    required this.jenisDokumen,
    required this.fileName,
    required this.statusReview,
    required this.tanggalUpload,
    this.guruId,
    this.fileMime,
    this.catatanReview,
    this.reviewedBy,
    this.reviewedAt,
    this.versi,
  });

  factory PerangkatModel.fromJson(Map<String, dynamic> json) {
    return PerangkatModel(
      id: json['id'] as int,
      guruId: json['guru_id'] as String?,
      namaGuru: json['nama_guru'] as String? ?? '-',
      namaDokumen: json['nama_dokumen'] as String? ?? '-',
      jenisDokumen: json['jenis_dokumen'] as String? ?? '-',
      fileName: json['file_name'] as String? ?? '-',
      fileMime: json['file_mime'] as String?,
      statusReview: json['status_review'] as String? ?? 'menunggu',
      catatanReview: json['catatan_review'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
      versi: json['versi'] as int?,
      tanggalUpload: json['tanggal_upload'] as String? ?? '',
    );
  }

  final int id;
  final String? guruId;
  final String namaGuru;
  final String namaDokumen;
  final String jenisDokumen;
  final String fileName;
  final String? fileMime;
  final String statusReview;
  final String? catatanReview;
  final String? reviewedBy;
  final String? reviewedAt;
  final int? versi;
  final String tanggalUpload;
}

// ─── RIWAYAT REVIEW ───────────────────────────────────────────

class RiwayatReviewModel {
  const RiwayatReviewModel({
    required this.id,
    required this.reviewerRole,
    required this.reviewerNama,
    required this.status,
    required this.createdAt,
    this.komentar,
  });

  factory RiwayatReviewModel.fromJson(Map<String, dynamic> json) {
    return RiwayatReviewModel(
      id: json['id'] as int,
      reviewerRole: json['reviewer_role'] as String? ?? '-',
      reviewerNama: json['reviewer_nama'] as String? ?? '-',
      status: json['status'] as String? ?? '-',
      komentar: json['komentar'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final int id;
  final String reviewerRole;
  final String reviewerNama;
  final String status;
  final String? komentar;
  final String createdAt;
}

// ─── EVALUASI GURU ─────────────────────────────────────────────

class EvaluasiGuruModel {
  const EvaluasiGuruModel({
    required this.id,
    required this.namaGuru,
    required this.evaluatorNama,
    required this.evaluatorRole,
    required this.createdAt,
    this.guruId,
    this.mapel,
    this.semester,
    this.skor,
    this.predikat,
    this.catatan,
  });

  factory EvaluasiGuruModel.fromJson(Map<String, dynamic> json) {
    return EvaluasiGuruModel(
      id: json['id'] as int,
      guruId: json['guru_id'] as String?,
      namaGuru: json['nama_guru'] as String? ?? '-',
      mapel: json['mapel'] as String?,
      semester: json['semester'] as String?,
      skor: json['skor'] != null ? (json['skor'] as num).toInt() : null,
      predikat: json['predikat'] as String?,
      catatan: json['catatan'] as String?,
      evaluatorNama: json['evaluator_nama'] as String? ?? '-',
      evaluatorRole: json['evaluator_role'] as String? ?? '-',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final int id;
  final String? guruId;
  final String namaGuru;
  final String? mapel;
  final String? semester;
  final int? skor;
  final String? predikat;
  final String? catatan;
  final String evaluatorNama;
  final String evaluatorRole;
  final String createdAt;
}

// ─── GURU MAPEL (untuk dropdown evaluasi) ─────────────────────

class GuruMapelModel {
  const GuruMapelModel({
    required this.id,
    required this.nama,
    required this.username,
    this.mapel,
    this.email,
  });

  factory GuruMapelModel.fromJson(Map<String, dynamic> json) {
    return GuruMapelModel(
      id: json['id'] as String? ?? '',
      nama: json['nama'] as String? ?? '-',
      username: json['username'] as String? ?? '-',
      mapel: json['mapel'] as String?,
      email: json['email'] as String?,
    );
  }

  final String id;
  final String nama;
  final String username;
  final String? mapel;
  final String? email;
}

// ─── CATATAN MENGAJAR ──────────────────────────────────────────

class CatatanMengajarModel {
  const CatatanMengajarModel({
    required this.id,
    required this.namaGuru,
    required this.materi,
    required this.tanggal,
    this.guruId,
    this.mataPelajaran,
    this.jamMulai,
    this.jamSelesai,
    this.metode,
    this.kendala,
    this.tindakLanjut,
  });

  factory CatatanMengajarModel.fromJson(Map<String, dynamic> json) {
    return CatatanMengajarModel(
      id: json['id'] as int,
      guruId: json['guru_id'] as String?,
      namaGuru: json['nama_guru'] as String? ?? '-',
      mataPelajaran: json['mata_pelajaran'] as String?,
      tanggal: json['tanggal'] as String? ?? '',
      jamMulai: json['jam_mulai'] as String?,
      jamSelesai: json['jam_selesai'] as String?,
      materi: json['materi'] as String? ?? '-',
      metode: json['metode'] as String?,
      kendala: json['kendala'] as String?,
      tindakLanjut: json['tindak_lanjut'] as String?,
    );
  }

  final int id;
  final String? guruId;
  final String namaGuru;
  final String? mataPelajaran;
  final String tanggal;
  final String? jamMulai;
  final String? jamSelesai;
  final String materi;
  final String? metode;
  final String? kendala;
  final String? tindakLanjut;
}
