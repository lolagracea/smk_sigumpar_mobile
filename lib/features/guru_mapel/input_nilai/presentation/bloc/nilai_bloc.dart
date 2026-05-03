// lib/features/guru_mapel/input_nilai/presentation/bloc/nilai_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../shared/models/shared_models.dart';
import '../../data/models/nilai_model.dart';
import '../../data/repositories/nilai_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────
abstract class NilaiEvent extends Equatable {
  const NilaiEvent();
  @override List<Object?> get props => [];
}
class NilaiLoadMaster   extends NilaiEvent {}
class NilaiFetch        extends NilaiEvent {}
class NilaiSave         extends NilaiEvent {}

class NilaiKelasChanged extends NilaiEvent {
  final KelasModel kelas;
  const NilaiKelasChanged(this.kelas);
  @override List<Object?> get props => [kelas];
}
class NilaiMapelChanged extends NilaiEvent {
  final MapelModel? mapel;
  const NilaiMapelChanged(this.mapel);
  @override List<Object?> get props => [mapel];
}
class NilaiTahunChanged extends NilaiEvent {
  final String tahun;
  const NilaiTahunChanged(this.tahun);
  @override List<Object?> get props => [tahun];
}
class NilaiUpdate extends NilaiEvent {
  final int siswaId;
  final String field;
  final double value;
  const NilaiUpdate(this.siswaId, this.field, this.value);
  @override List<Object?> get props => [siswaId, field, value];
}

// ── State ──────────────────────────────────────────────────────────────────
class NilaiState extends Equatable {
  final List<KelasModel>      kelasList;
  final List<MapelModel>      mapelList;
  final List<NilaiSiswaModel> rows;
  final KelasModel?           selectedKelas;
  final MapelModel?           selectedMapel;
  final String                tahunAjar;
  final bool  isLoadingMaster;
  final bool  isLoading;
  final bool  isSaving;
  final bool  sudahCari;
  final String? error;
  final String? successMessage;

  const NilaiState({
    this.kelasList      = const [],
    this.mapelList      = const [],
    this.rows           = const [],
    this.selectedKelas,
    this.selectedMapel,
    this.tahunAjar      = '2024/2025',
    this.isLoadingMaster = false,
    this.isLoading      = false,
    this.isSaving       = false,
    this.sudahCari      = false,
    this.error,
    this.successMessage,
  });

  NilaiState copyWith({
    List<KelasModel>? kelasList,
    List<MapelModel>? mapelList,
    List<NilaiSiswaModel>? rows,
    KelasModel? selectedKelas,
    MapelModel? Function()? selectedMapel,
    String? tahunAjar,
    bool? isLoadingMaster,
    bool? isLoading,
    bool? isSaving,
    bool? sudahCari,
    String? Function()? error,
    String? Function()? successMessage,
  }) => NilaiState(
    kelasList       : kelasList       ?? this.kelasList,
    mapelList       : mapelList       ?? this.mapelList,
    rows            : rows            ?? this.rows,
    selectedKelas   : selectedKelas   ?? this.selectedKelas,
    selectedMapel   : selectedMapel  != null ? selectedMapel() : this.selectedMapel,
    tahunAjar       : tahunAjar       ?? this.tahunAjar,
    isLoadingMaster : isLoadingMaster ?? this.isLoadingMaster,
    isLoading       : isLoading       ?? this.isLoading,
    isSaving        : isSaving        ?? this.isSaving,
    sudahCari       : sudahCari       ?? this.sudahCari,
    error           : error          != null ? error() : this.error,
    successMessage  : successMessage != null ? successMessage() : this.successMessage,
  );

  @override
  List<Object?> get props => [kelasList, mapelList, rows, selectedKelas,
    selectedMapel, tahunAjar, isLoadingMaster, isLoading, isSaving,
    sudahCari, error, successMessage];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class NilaiBloc extends Bloc<NilaiEvent, NilaiState> {
  final NilaiRepository _repo;

  NilaiBloc({required NilaiRepository repository})
      : _repo = repository,
        super(const NilaiState()) {
    on<NilaiLoadMaster>(_onLoadMaster);
    on<NilaiKelasChanged>(_onKelas);
    on<NilaiMapelChanged>(_onMapel);
    on<NilaiTahunChanged>(_onTahun);
    on<NilaiFetch>(_onFetch);
    on<NilaiUpdate>(_onUpdate);
    on<NilaiSave>(_onSave);
  }

  Future<void> _onLoadMaster(NilaiLoadMaster e, Emitter<NilaiState> emit) async {
    emit(state.copyWith(isLoadingMaster: true));
    try {
      final kelas = await _repo.getKelas();
      final mapel = await _repo.getMapel();
      emit(state.copyWith(kelasList: kelas, mapelList: mapel, isLoadingMaster: false));
    } catch (e) {
      emit(state.copyWith(isLoadingMaster: false, error: () => e.toString()));
    }
  }

  void _onKelas(NilaiKelasChanged e, Emitter<NilaiState> emit) =>
      emit(state.copyWith(selectedKelas: e.kelas, rows: [], sudahCari: false));

  void _onMapel(NilaiMapelChanged e, Emitter<NilaiState> emit) =>
      emit(state.copyWith(selectedMapel: () => e.mapel));

  void _onTahun(NilaiTahunChanged e, Emitter<NilaiState> emit) =>
      emit(state.copyWith(tahunAjar: e.tahun));

  Future<void> _onFetch(NilaiFetch e, Emitter<NilaiState> emit) async {
    if (state.selectedKelas == null) return;
    emit(state.copyWith(isLoading: true, sudahCari: false));
    try {
      final rows = await _repo.getSiswaWithNilai(
        kelasId  : state.selectedKelas!.id,
        mapelId  : state.selectedMapel?.id,
        tahunAjar: state.tahunAjar,
      );
      emit(state.copyWith(rows: rows, isLoading: false, sudahCari: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: () => e.toString()));
    }
  }

  void _onUpdate(NilaiUpdate e, Emitter<NilaiState> emit) {
    final rows = state.rows.map((r) {
      if (r.siswaId != e.siswaId) return r;
      return r.copyWith(
        nilaiTugas  : e.field == 'tugas'   ? e.value : null,
        nilaiKuis   : e.field == 'kuis'    ? e.value : null,
        nilaiUts    : e.field == 'uts'     ? e.value : null,
        nilaiUas    : e.field == 'uas'     ? e.value : null,
        nilaiPraktik: e.field == 'praktik' ? e.value : null,
      );
    }).toList();
    emit(state.copyWith(rows: rows));
  }

  Future<void> _onSave(NilaiSave e, Emitter<NilaiState> emit) async {
    emit(state.copyWith(isSaving: true));
    try {
      await _repo.saveBulk(state.rows, state.selectedKelas!.id,
          state.selectedMapel?.id, state.tahunAjar);
      emit(state.copyWith(
          isSaving: false,
          successMessage: () => 'Nilai ${state.rows.length} siswa berhasil disimpan'));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: () => e.toString()));
    }
  }
}
