import '../models/arsip_surat_model.dart';
import '../models/kelas_model.dart';
import '../models/pengumuman_model.dart';
import '../models/siswa_model.dart';

class AcademicService {
  Future<List<KelasModel>> getKelas() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const <KelasModel>[
      KelasModel(id: 1, nama: 'X RPL 1', tingkat: 'X', waliKelas: 'Ibu Sari'),
      KelasModel(id: 2, nama: 'XI RPL 1', tingkat: 'XI', waliKelas: 'Bapak Budi'),
      KelasModel(id: 3, nama: 'XII RPL 1', tingkat: 'XII', waliKelas: 'Ibu Tiur'),
    ];
  }

  Future<List<SiswaModel>> getSiswa() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const <SiswaModel>[
      SiswaModel(id: 1, nama: 'Andi Simanjuntak', nis: '24001', kelas: 'X RPL 1'),
      SiswaModel(id: 2, nama: 'Berta Silalahi', nis: '24002', kelas: 'XI RPL 1'),
      SiswaModel(id: 3, nama: 'Cindy Hutagalung', nis: '24003', kelas: 'XII RPL 1'),
    ];
  }

  Future<List<PengumumanModel>> getPengumuman() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return <PengumumanModel>[
      PengumumanModel(
        id: 1,
        judul: 'Libur Nasional',
        isi: 'Kegiatan belajar diliburkan pada hari Jumat.',
        tanggal: DateTime(2026, 4, 21),
      ),
      PengumumanModel(
        id: 2,
        judul: 'Rapat Tata Usaha',
        isi: 'Rapat dilaksanakan pukul 10.00 WIB di ruang rapat.',
        tanggal: DateTime(2026, 4, 19),
      ),
    ];
  }

  Future<List<ArsipSuratModel>> getArsipSurat() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return <ArsipSuratModel>[
      ArsipSuratModel(
        id: 1,
        nomor: '420/SMKN1S/001',
        perihal: 'Undangan Orang Tua',
        fileName: 'undangan-orang-tua.pdf',
        tanggal: DateTime(2026, 4, 10),
      ),
      ArsipSuratModel(
        id: 2,
        nomor: '420/SMKN1S/002',
        perihal: 'Edaran Kegiatan Sekolah',
        fileName: 'edaran-kegiatan.pdf',
        tanggal: DateTime(2026, 4, 12),
      ),
    ];
  }
}
