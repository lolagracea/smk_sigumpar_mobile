// lib/features/guru_mapel/perangkat/presentation/bloc/perangkat_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/perangkat_model.dart';
import '../../data/perangkat_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────
abstract class PerangkatEvent extends Equatable {
  const PerangkatEvent();
  @override List<Object?> get props => [];
}
class PerangkatLoad extends PerangkatEvent {}
class PerangkatFilterChanged extends PerangkatEvent {
  final String? jenis;
  const PerangkatFilterChanged(this.jenis);
  @override List<Object?> get props => [jenis];
}
class PerangkatUploadRequested extends PerangkatEvent {
  final String namaDokumen;
  final String jenisDokumen;
  final String filePath;
  final String fileName;
  const PerangkatUploadRequested({
    required this.namaDokumen,
    required this.jenisDokumen,
    required this.filePath,
    required this.fileName,
  });
  @override List<Object?> get props => [namaDokumen, jenisDokumen, filePath];
}
class PerangkatDeleteRequested extends PerangkatEvent {
  final int id;
  const PerangkatDeleteRequested(this.id);
  @override List<Object?> get props => [id];
}

// ── States ─────────────────────────────────────────────────────────────────
abstract class PerangkatState extends Equatable {
  const PerangkatState();
  @override List<Object?> get props => [];
}
class PerangkatInitial extends PerangkatState {}
class PerangkatLoading extends PerangkatState {}
class PerangkatLoaded extends PerangkatState {
  final List<PerangkatModel> all;
  final List<PerangkatModel> filtered;
  final String? filterJenis;
  const PerangkatLoaded({required this.all, required this.filtered, this.filterJenis});
  @override List<Object?> get props => [all, filtered, filterJenis];
}
class PerangkatActionSuccess extends PerangkatState {
  final String message;
  const PerangkatActionSuccess(this.message);
  @override List<Object?> get props => [message];
}
class PerangkatError extends PerangkatState {
  final String message;
  const PerangkatError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class PerangkatBloc extends Bloc<PerangkatEvent, PerangkatState> {
  final PerangkatRepository _repo;
  List<PerangkatModel> _all = [];
  String? _filterJenis;

  PerangkatBloc({required PerangkatRepository repository})
      : _repo = repository,
        super(PerangkatInitial()) {
    on<PerangkatLoad>(_onLoad);
    on<PerangkatUploadRequested>(_onUpload);
    on<PerangkatDeleteRequested>(_onDelete);
    on<PerangkatFilterChanged>(_onFilter);
  }

  List<PerangkatModel> _apply(String? jenis) =>
      jenis == null ? _all : _all.where((e) => e.jenisDokumen == jenis).toList();

  Future<void> _onLoad(PerangkatLoad e, Emitter<PerangkatState> emit) async {
    emit(PerangkatLoading());
    try {
      _all = await _repo.getAll();
      emit(PerangkatLoaded(all: _all, filtered: _apply(_filterJenis), filterJenis: _filterJenis));
    } catch (e) {
      emit(PerangkatError(e.toString()));
    }
  }

  Future<void> _onUpload(PerangkatUploadRequested e, Emitter<PerangkatState> emit) async {
    try {
      await _repo.upload(
          namaDokumen: e.namaDokumen, jenisDokumen: e.jenisDokumen,
          filePath: e.filePath, fileName: e.fileName);
      emit(const PerangkatActionSuccess('Dokumen berhasil diunggah'));
      add(PerangkatLoad());
    } catch (err) {
      emit(PerangkatError(err.toString()));
    }
  }

  Future<void> _onDelete(PerangkatDeleteRequested e, Emitter<PerangkatState> emit) async {
    try {
      await _repo.delete(e.id);
      emit(const PerangkatActionSuccess('Dokumen berhasil dihapus'));
      add(PerangkatLoad());
    } catch (err) {
      emit(PerangkatError(err.toString()));
    }
  }

  void _onFilter(PerangkatFilterChanged e, Emitter<PerangkatState> emit) {
    _filterJenis = e.jenis;
    emit(PerangkatLoaded(all: _all, filtered: _apply(_filterJenis), filterJenis: _filterJenis));
  }
}
