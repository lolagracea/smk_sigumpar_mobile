import 'package:flutter/material.dart';

import '../../../../data/models/absensi_guru_model.dart';
import '../../../../data/models/class_model.dart';
import '../../../../data/models/schedule_model.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../../data/repositories/learning_repository.dart';
import '../../../../data/repositories/student_repository.dart';

enum VicePrincipalState {
  initial,
  loading,
  loaded,
  error,
}

class VicePrincipalProvider extends ChangeNotifier {
  final AcademicRepository academicRepository;
  final LearningRepository learningRepository;
  final StudentRepository studentRepository;

  VicePrincipalProvider({
    required this.academicRepository,
    required this.learningRepository,
    required this.studentRepository,
  });

  VicePrincipalState state = VicePrincipalState.initial;
  String? errorMessage;

  List<ScheduleModel> schedules = [];
  List<AbsensiGuruModel> teacherAttendances = [];
  List<Map<String, dynamic>> learningDevices = [];
  List<Map<String, dynamic>> parentingNotes = [];
  List<ClassModel> classes = [];

  DateTime selectedDate = DateTime.now();

  bool get isLoading => state == VicePrincipalState.loading;
  bool get isError => state == VicePrincipalState.error;

  int get totalJadwal => schedules.length;
  int get totalAbsensiGuru => teacherAttendances.length;
  int get totalPerangkat => learningDevices.length;
  int get totalParenting => parentingNotes.length;

  int get totalHadir => teacherAttendances
      .where((item) => item.status == StatusKehadiran.hadir)
      .length;

  int get totalTerlambat => teacherAttendances
      .where((item) => item.status == StatusKehadiran.terlambat)
      .length;

  int get totalIzin => teacherAttendances
      .where((item) => item.status == StatusKehadiran.izin)
      .length;

  int get totalSakit => teacherAttendances
      .where((item) => item.status == StatusKehadiran.sakit)
      .length;

  int get totalAlpa => teacherAttendances
      .where((item) => item.status == StatusKehadiran.alpa)
      .length;

  int get totalPerangkatMenunggu {
    return learningDevices.where((item) {
      final status = _read(item, [
        'status_wakasek',
        'status_review_wakasek',
        'status',
      ]).toLowerCase();

      return status.isEmpty ||
          status == '-' ||
          status == 'pending' ||
          status == 'menunggu' ||
          status == 'diajukan';
    }).length;
  }

  int get totalPerangkatDisetujui {
    return learningDevices.where((item) {
      final status = _read(item, [
        'status_wakasek',
        'status_review_wakasek',
        'status',
      ]).toLowerCase();

      return status == 'disetujui' ||
          status == 'approved' ||
          status == 'diterima';
    }).length;
  }

  int get totalPerangkatDitolak {
    return learningDevices.where((item) {
      final status = _read(item, [
        'status_wakasek',
        'status_review_wakasek',
        'status',
      ]).toLowerCase();

      return status == 'ditolak' || status == 'rejected';
    }).length;
  }

  String get selectedDateQuery {
    return selectedDate.toIso8601String().split('T').first;
  }

  Future<void> loadDashboard() async {
    _setLoading();

    try {
      final jadwal = await academicRepository.getSchedules();
      final absensi = await learningRepository.getAbsensiGuruList(
        date: selectedDateQuery,
      );
      final perangkat = await learningRepository.getLearningDevices();
      final parenting = await studentRepository.getParentingNotes();

      schedules = jadwal;
      teacherAttendances = absensi;
      learningDevices = perangkat.items;
      parentingNotes = parenting.items;

      _setLoaded();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> loadJadwal() async {
    _setLoading();

    try {
      schedules = await academicRepository.getSchedules();
      _setLoaded();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> loadAbsensiGuru({DateTime? date}) async {
    _setLoading();

    try {
      if (date != null) selectedDate = date;

      teacherAttendances = await learningRepository.getAbsensiGuruList(
        date: selectedDateQuery,
      );

      _setLoaded();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> loadPerangkat() async {
    _setLoading();

    try {
      final result = await learningRepository.getLearningDevices();
      learningDevices = result.items;
      _setLoaded();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> loadParenting() async {
    _setLoading();

    try {
      final classResult = await academicRepository.getClasses();
      final parentingResult = await studentRepository.getParentingNotes();

      classes = classResult.items;
      parentingNotes = parentingResult.items;

      _setLoaded();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> loadLaporanRingkas({DateTime? date}) async {
    _setLoading();

    try {
      if (date != null) selectedDate = date;

      final jadwal = await academicRepository.getSchedules();
      final absensi = await learningRepository.getAbsensiGuruList(
        date: selectedDateQuery,
      );
      final perangkat = await learningRepository.getLearningDevices();
      final parenting = await studentRepository.getParentingNotes();

      schedules = jadwal;
      teacherAttendances = absensi;
      learningDevices = perangkat.items;
      parentingNotes = parenting.items;

      _setLoaded();
    } catch (e) {
      _setError(e);
    }
  }

  Future<bool> submitWakasekReview({
    required int id,
    required String status,
    String? catatan,
  }) async {
    try {
      await learningRepository.submitVicePrincipalReview(
        id,
        {
          'status_wakasek': status,
          'catatan_wakasek': catatan ?? '',
        },
      );

      await loadPerangkat();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  void _setLoading() {
    state = VicePrincipalState.loading;
    errorMessage = null;
    notifyListeners();
  }

  void _setLoaded() {
    state = VicePrincipalState.loaded;
    errorMessage = null;
    notifyListeners();
  }

  void _setError(Object error) {
    state = VicePrincipalState.error;
    errorMessage = error.toString();
    notifyListeners();
  }

  String _read(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }
}