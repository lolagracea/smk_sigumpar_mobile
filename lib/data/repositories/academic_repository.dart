import '../models/arsip_surat_model.dart';
import '../models/kelas_model.dart';
import '../models/pengumuman_model.dart';
import '../models/siswa_model.dart';
import '../services/academic_service.dart';

class AcademicRepository {
  AcademicRepository({AcademicService? service})
      : _service = service ?? AcademicService();

  final AcademicService _service;

  Future<List<KelasModel>> getKelas() => _service.getKelas();

  Future<List<SiswaModel>> getSiswa() => _service.getSiswa();

  Future<List<PengumumanModel>> getPengumuman() => _service.getPengumuman();

  Future<List<ArsipSuratModel>> getArsipSurat() => _service.getArsipSurat();
}
