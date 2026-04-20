import '../models/arsip_surat.dart';
import '../models/kelas.dart';
import '../models/pengumuman.dart';
import '../models/siswa.dart';
import '../remote/academic_api.dart';

class AcademicRepository {
  AcademicRepository(this._api);
  final AcademicApi _api;

  Future<List<Kelas>> fetchKelas() async {
    await _api.getKelas();
    return const [
      Kelas(id: 1, nama: 'X TKJ 1', tingkat: 'X', waliKelas: 'Ibu Ratna'),
      Kelas(id: 2, nama: 'XI RPL 1', tingkat: 'XI', waliKelas: 'Pak Joni'),
    ];
  }

  Future<List<Siswa>> fetchSiswa() async {
    await _api.getSiswa();
    return const [
      Siswa(id: 1, nama: 'Budi Situmorang', nisn: '1234567890', kelas: 'X TKJ 1'),
      Siswa(id: 2, nama: 'Tiur Simarmata', nisn: '0987654321', kelas: 'XI RPL 1'),
    ];
  }

  Future<List<Pengumuman>> fetchPengumuman() async {
    await _api.getPengumuman();
    return [
      Pengumuman(
        id: 1,
        judul: 'Libur Semester',
        isi: 'Kegiatan belajar dihentikan sementara selama libur semester.',
        tanggal: DateTime.now(),
      ),
    ];
  }

  Future<List<ArsipSurat>> fetchArsipSurat() async {
    await _api.getArsipSurat();
    return const [
      ArsipSurat(
        id: 1,
        nomorSurat: '420/SMKN1S/2026',
        perihal: 'Undangan Rapat Orang Tua',
        fileUrl: null,
      ),
    ];
  }
}
