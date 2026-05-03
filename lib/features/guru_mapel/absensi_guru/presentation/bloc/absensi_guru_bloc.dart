// lib/features/absensi_guru/presentation/bloc/absensi_guru_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/absensi_guru_model.dart';
import '../../data/repositories/absensi_guru_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────
abstract class AbsensiGuruEvent extends Equatable {
  const AbsensiGuruEvent();
  @override
  List<Object?> get props => [];
}

class AbsensiGuruLoadRequested extends AbsensiGuruEvent {
  final String? tanggal;
  const AbsensiGuruLoadRequested({this.tanggal});
  @override
  List<Object?> get props => [tanggal];
}

class AbsensiGuruCreateRequested extends AbsensiGuruEvent {
  final AbsensiGuruModel model;
  const AbsensiGuruCreateRequested(this.model);
  @override
  List<Object?> get props => [model];
}

class AbsensiGuruUpdateRequested extends AbsensiGuruEvent {
  final int id;
  final AbsensiGuruModel model;
  const AbsensiGuruUpdateRequested(this.id, this.model);
  @override
  List<Object?> get props => [id, model];
}

class AbsensiGuruDeleteRequested extends AbsensiGuruEvent {
  final int id;
  const AbsensiGuruDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class AbsensiGuruFilterChanged extends AbsensiGuruEvent {
  final String tanggal;
  const AbsensiGuruFilterChanged(this.tanggal);
  @override
  List<Object?> get props => [tanggal];
}

// ── States ─────────────────────────────────────────────────────────────────
abstract class AbsensiGuruState extends Equatable {
  const AbsensiGuruState();
  @override
  List<Object?> get props => [];
}

class AbsensiGuruInitial extends AbsensiGuruState {}
class AbsensiGuruLoading extends AbsensiGuruState {}

class AbsensiGuruLoaded extends AbsensiGuruState {
  final List<AbsensiGuruModel> items;
  final AbsensiSummary summary;
  final String filterTanggal;

  const AbsensiGuruLoaded({
    required this.items,
    required this.summary,
    required this.filterTanggal,
  });
  @override
  List<Object?> get props => [items, summary, filterTanggal];
}

class AbsensiGuruActionSuccess extends AbsensiGuruState {
  final String message;
  const AbsensiGuruActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AbsensiGuruError extends AbsensiGuruState {
  final String message;
  const AbsensiGuruError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class AbsensiGuruBloc extends Bloc<AbsensiGuruEvent, AbsensiGuruState> {
  final AbsensiGuruRepository _repository;
  String _currentTanggal = _todayIso();

  AbsensiGuruBloc({required AbsensiGuruRepository repository})
      : _repository = repository,
        super(AbsensiGuruInitial()) {
    on<AbsensiGuruLoadRequested>(_onLoad);
    on<AbsensiGuruCreateRequested>(_onCreate);
    on<AbsensiGuruUpdateRequested>(_onUpdate);
    on<AbsensiGuruDeleteRequested>(_onDelete);
    on<AbsensiGuruFilterChanged>(_onFilterChanged);
  }

  static String _todayIso() => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _onLoad(
      AbsensiGuruLoadRequested event, Emitter<AbsensiGuruState> emit) async {
    emit(AbsensiGuruLoading());
    try {
      final tanggal = event.tanggal ?? _currentTanggal;
      _currentTanggal = tanggal;
      final items = await _repository.getAll(tanggal: tanggal);
      emit(AbsensiGuruLoaded(
        items: items,
        summary: AbsensiSummary.fromList(items),
        filterTanggal: tanggal,
      ));
    } catch (e) {
      emit(AbsensiGuruError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onCreate(
      AbsensiGuruCreateRequested event, Emitter<AbsensiGuruState> emit) async {
    try {
      await _repository.create(event.model);
      emit(const AbsensiGuruActionSuccess('Absensi berhasil disimpan'));
      add(AbsensiGuruLoadRequested(tanggal: _currentTanggal));
    } catch (e) {
      emit(AbsensiGuruError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onUpdate(
      AbsensiGuruUpdateRequested event, Emitter<AbsensiGuruState> emit) async {
    try {
      await _repository.update(event.id, event.model);
      emit(const AbsensiGuruActionSuccess('Absensi berhasil diperbarui'));
      add(AbsensiGuruLoadRequested(tanggal: _currentTanggal));
    } catch (e) {
      emit(AbsensiGuruError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onDelete(
      AbsensiGuruDeleteRequested event, Emitter<AbsensiGuruState> emit) async {
    try {
      await _repository.delete(event.id);
      emit(const AbsensiGuruActionSuccess('Absensi berhasil dihapus'));
      add(AbsensiGuruLoadRequested(tanggal: _currentTanggal));
    } catch (e) {
      emit(AbsensiGuruError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onFilterChanged(
      AbsensiGuruFilterChanged event, Emitter<AbsensiGuruState> emit) async {
    _currentTanggal = event.tanggal;
    add(AbsensiGuruLoadRequested(tanggal: event.tanggal));
  }
}
