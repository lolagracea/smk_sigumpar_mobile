import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
// lib/features/absensi_siswa/presentation/bloc/absensi_siswa_bloc.dart
import 'package:equatable/equatable.dart';
import '../../../../../shared/models/shared_models.dart';
import '../../data/models/absensi_siswa_model.dart';
import '../../data/repositories/absensi_siswa_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────
abstract class AbsensiSiswaEvent extends Equatable {
  const AbsensiSiswaEvent();
  @override
  List<Object?> get props => [];
}

class AbsensiSiswaLoadMasterData extends AbsensiSiswaEvent {}

class AbsensiSiswaKelasChanged extends AbsensiSiswaEvent {
  final KelasModel kelas;
  const AbsensiSiswaKelasChanged(this.kelas);
  @override
  List<Object?> get props => [kelas];
}

class AbsensiSiswaMapelChanged extends AbsensiSiswaEvent {
  final MapelModel? mapel;
  const AbsensiSiswaMapelChanged(this.mapel);
  @override
  List<Object?> get props => [mapel];
}

class AbsensiSiswaTanggalChanged extends AbsensiSiswaEvent {
  final String tanggal;
  const AbsensiSiswaTanggalChanged(this.tanggal);
  @override
  List<Object?> get props => [tanggal];
}

class AbsensiSiswaFetch extends AbsensiSiswaEvent {}

class AbsensiSiswaStatusChanged extends AbsensiSiswaEvent {
  final int siswaId;
  final String status;
  const AbsensiSiswaStatusChanged(this.siswaId, this.status);
  @override
  List<Object?> get props => [siswaId, status];
}

class AbsensiSiswaSaveRequested extends AbsensiSiswaEvent {}

// ── States ─────────────────────────────────────────────────────────────────
class AbsensiSiswaState extends Equatable {
  final List<KelasModel> kelasList;
  final List<MapelModel> mapelList;
  final List<SiswaModel> siswaList;
  final KelasModel? selectedKelas;
  final MapelModel? selectedMapel;
  final String tanggal;
  final Map<int, String> attendance; // siswa_id -> status
  final bool isLoadingMaster;
  final bool isLoadingSiswa;
  final bool isSaving;
  final bool sudahCari;
  final String? error;
  final String? successMessage;

  const AbsensiSiswaState({
    this.kelasList = const [],
    this.mapelList = const [],
    this.siswaList = const [],
    this.selectedKelas,
    this.selectedMapel,
    this.tanggal = '',
    this.attendance = const {},
    this.isLoadingMaster = false,
    this.isLoadingSiswa = false,
    this.isSaving = false,
    this.sudahCari = false,
    this.error,
    this.successMessage,
  });

  AbsensiSiswaState copyWith({
    List<KelasModel>? kelasList,
    List<MapelModel>? mapelList,
    List<SiswaModel>? siswaList,
    KelasModel? selectedKelas,
    MapelModel? Function()? selectedMapel,
    String? tanggal,
    Map<int, String>? attendance,
    bool? isLoadingMaster,
    bool? isLoadingSiswa,
    bool? isSaving,
    bool? sudahCari,
    String? Function()? error,
    String? Function()? successMessage,
  }) {
    return AbsensiSiswaState(
      kelasList: kelasList ?? this.kelasList,
      mapelList: mapelList ?? this.mapelList,
      siswaList: siswaList ?? this.siswaList,
      selectedKelas: selectedKelas ?? this.selectedKelas,
      selectedMapel:
          selectedMapel != null ? selectedMapel() : this.selectedMapel,
      tanggal: tanggal ?? this.tanggal,
      attendance: attendance ?? this.attendance,
      isLoadingMaster: isLoadingMaster ?? this.isLoadingMaster,
      isLoadingSiswa: isLoadingSiswa ?? this.isLoadingSiswa,
      isSaving: isSaving ?? this.isSaving,
      sudahCari: sudahCari ?? this.sudahCari,
      error: error != null ? error() : this.error,
      successMessage:
          successMessage != null ? successMessage() : this.successMessage,
    );
  }

  Map<String, int> get stats {
    final s = <String, int>{
      'hadir': 0, 'izin': 0, 'sakit': 0, 'alpa': 0, 'terlambat': 0
    };
    for (final v in attendance.values) {
      s[v] = (s[v] ?? 0) + 1;
    }
    return s;
  }

  @override
  List<Object?> get props => [
        kelasList, mapelList, siswaList, selectedKelas, selectedMapel,
        tanggal, attendance, isLoadingMaster, isLoadingSiswa, isSaving,
        sudahCari, error, successMessage,
      ];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class AbsensiSiswaBloc
    extends Bloc<AbsensiSiswaEvent, AbsensiSiswaState> {
  final AbsensiSiswaRepository _repo;

  AbsensiSiswaBloc({required AbsensiSiswaRepository repository})
      : _repo = repository,
        super(AbsensiSiswaState(
            tanggal: DateTime.now().toIso8601String().substring(0, 10))) {
    on<AbsensiSiswaLoadMasterData>(_onLoadMaster);
    on<AbsensiSiswaKelasChanged>(_onKelasChanged);
    on<AbsensiSiswaMapelChanged>(_onMapelChanged);
    on<AbsensiSiswaTanggalChanged>(_onTanggalChanged);
    on<AbsensiSiswaFetch>(_onFetch);
    on<AbsensiSiswaStatusChanged>(_onStatusChanged);
    on<AbsensiSiswaSaveRequested>(_onSave);
  }

  Future<void> _onLoadMaster(
      AbsensiSiswaLoadMasterData event, Emitter<AbsensiSiswaState> emit) async {
    emit(state.copyWith(isLoadingMaster: true, error: () => null));
    try {
      final kelas = await _repo.getKelas();
      emit(state.copyWith(kelasList: kelas, isLoadingMaster: false));
    } catch (e) {
      emit(state.copyWith(
          isLoadingMaster: false,
          error: () => e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onKelasChanged(
      AbsensiSiswaKelasChanged event, Emitter<AbsensiSiswaState> emit) async {
    emit(state.copyWith(
      selectedKelas: event.kelas,
      selectedMapel: () => null,
      siswaList: [],
      mapelList: [],
      attendance: {},
      sudahCari: false,
    ));
    try {
      final mapels = await _repo.getMapelByKelas(event.kelas.id);
      final siswas = await _repo.getSiswaByKelas(event.kelas.id);
      // Default semua "hadir"
      final att = <int, String>{};
      for (final s in siswas) att[s.id] = 'hadir';
      emit(state.copyWith(
          mapelList: mapels, siswaList: siswas, attendance: att));
    } catch (_) {}
  }

  void _onMapelChanged(
      AbsensiSiswaMapelChanged event, Emitter<AbsensiSiswaState> emit) {
    emit(state.copyWith(
        selectedMapel: () => event.mapel, sudahCari: false));
  }

  void _onTanggalChanged(
      AbsensiSiswaTanggalChanged event, Emitter<AbsensiSiswaState> emit) {
    emit(state.copyWith(tanggal: event.tanggal, sudahCari: false));
  }

  Future<void> _onFetch(
      AbsensiSiswaFetch event, Emitter<AbsensiSiswaState> emit) async {
    if (state.selectedKelas == null || state.tanggal.isEmpty) return;
    emit(state.copyWith(isLoadingSiswa: true, sudahCari: false));
    try {
      final existing = await _repo.getAbsensi(
        kelasId: state.selectedKelas!.id,
        tanggal: state.tanggal,
        mapelId: state.selectedMapel?.id,
      );
      // Merge existing dengan default hadir
      final att = Map<int, String>.from(state.attendance);
      for (final a in existing) {
        att[a.siswaId] = a.status;
      }
      emit(state.copyWith(
          attendance: att, isLoadingSiswa: false, sudahCari: true));
    } catch (e) {
      emit(state.copyWith(
          isLoadingSiswa: false,
          error: () => e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void _onStatusChanged(
      AbsensiSiswaStatusChanged event, Emitter<AbsensiSiswaState> emit) {
    final att = Map<int, String>.from(state.attendance);
    att[event.siswaId] = event.status;
    emit(state.copyWith(attendance: att));
  }

  Future<void> _onSave(
      AbsensiSiswaSaveRequested event, Emitter<AbsensiSiswaState> emit) async {
    emit(state.copyWith(isSaving: true, error: () => null));
    try {
      final items = state.siswaList.map((s) {
        return AbsensiSiswaModel(
          siswaId: s.id,
          kelasId: state.selectedKelas!.id,
          mapelId: state.selectedMapel?.id,
          tanggal: state.tanggal,
          status: state.attendance[s.id] ?? 'hadir',
        );
      }).toList();
      await _repo.saveBulk(items);
      emit(state.copyWith(
          isSaving: false,
          successMessage: () => 'Absensi ${items.length} siswa berhasil disimpan'));
    } catch (e) {
      emit(state.copyWith(
          isSaving: false,
          error: () => e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
