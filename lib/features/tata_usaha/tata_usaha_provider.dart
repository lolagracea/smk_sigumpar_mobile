import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../data/remote/academic_api.dart';
import '../../data/repositories/academic_repository.dart';
import '../../data/models/kelas.dart';
import '../../data/models/siswa.dart';
import '../../data/models/pengumuman.dart';
import '../../data/models/arsip_surat.dart';

class TataUsahaProvider extends ChangeNotifier {
  TataUsahaProvider()
      : _repository = AcademicRepository(
          AcademicApi(ApiClient()),
        );

  final AcademicRepository _repository;

  bool isLoading = false;
  List<Kelas> kelas = [];
  List<Siswa> siswa = [];
  List<Pengumuman> pengumuman = [];
  List<ArsipSurat> arsip = [];

  Future<void> loadKelas() async {
    isLoading = true;
    notifyListeners();
    kelas = await _repository.fetchKelas();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadSiswa() async {
    isLoading = true;
    notifyListeners();
    siswa = await _repository.fetchSiswa();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadPengumuman() async {
    isLoading = true;
    notifyListeners();
    pengumuman = await _repository.fetchPengumuman();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadArsip() async {
    isLoading = true;
    notifyListeners();
    arsip = await _repository.fetchArsipSurat();
    isLoading = false;
    notifyListeners();
  }
}
