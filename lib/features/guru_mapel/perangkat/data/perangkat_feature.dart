import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
// lib/features/perangkat/data/models/perangkat_model.dart
class PerangkatModel {
  final int? id;
  final String namaDokumen;
  final String jenisDokumen;
  final String? fileName;
  final String? fileMime;
  final String? fileUrl;
  final int versi;
  final String statusReview;
  final String? catatanReview;
  final DateTime? createdAt;
  final String? namaGuru;

  const PerangkatModel({
    this.id,
    required this.namaDokumen,
    required this.jenisDokumen,
    this.fileName,
    this.fileMime,
    this.fileUrl,
    this.versi = 1,
    this.statusReview = 'menunggu',
    this.catatanReview,
    this.createdAt,
    this.namaGuru,
  });

  factory PerangkatModel.fromJson(Map<String, dynamic> json) {
    return PerangkatModel(
      id: json['id'] as int?,
      namaDokumen: json['nama_dokumen']?.toString() ?? '',
      jenisDokumen: json['jenis_dokumen']?.toString() ?? 'RPP',
      fileName: json['file_name']?.toString(),
      fileMime: json['file_mime']?.toString(),
      fileUrl: json['file_url']?.toString(),
      versi: (json['versi'] as num?)?.toInt() ?? 1,
      statusReview: json['status_review']?.toString() ?? 'menunggu',
      catatanReview: json['catatan_review']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      namaGuru: json['nama_guru']?.toString(),
    );
  }
}

// Status Metadata
class StatusMeta {
  final String label;
  final Color color;
  final String icon;

  const StatusMeta(this.label, this.color, this.icon);

  static const Map<String, StatusMeta> all = {};
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// lib/features/perangkat/data/repositories/perangkat_repository.dart

class PerangkatRepository {
  final Dio _dio;

  PerangkatRepository() : _dio = ApiClient().learning;

  Future<List<PerangkatModel>> getAll() async {
    final res = await _dio.get('/api/learning/perangkat');
    final list = (res.data['data'] as List?) ?? (res.data as List? ?? []);
    return list.map((e) => PerangkatModel.fromJson(e)).toList();
  }

  Future<PerangkatModel> upload({
    required String namaDokumen,
    required String jenisDokumen,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'nama_dokumen': namaDokumen,
      'jenis_dokumen': jenisDokumen,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final res = await _dio.post('/api/learning/perangkat', data: formData);
    final data = res.data;
    return PerangkatModel.fromJson(
        (data['data'] ?? data) as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/api/learning/perangkat/$id');
  }

  Future<String> getDownloadUrl(int id) async {
    return '${_dio.options.baseUrl}/api/learning/perangkat/$id/download';
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// BLoC

abstract class PerangkatEvent extends Equatable {
  const PerangkatEvent();
  @override List<Object?> get props => [];
}
class PerangkatLoad extends PerangkatEvent {}
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
class PerangkatFilterChanged extends PerangkatEvent {
  final String? jenis;
  const PerangkatFilterChanged(this.jenis);
  @override List<Object?> get props => [jenis];
}

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

  List<PerangkatModel> _applyFilter(String? jenis) {
    if (jenis == null) return _all;
    return _all.where((e) => e.jenisDokumen == jenis).toList();
  }

  Future<void> _onLoad(PerangkatLoad e, Emitter<PerangkatState> emit) async {
    emit(PerangkatLoading());
    try {
      _all = await _repo.getAll();
      emit(PerangkatLoaded(
          all: _all, filtered: _applyFilter(_filterJenis), filterJenis: _filterJenis));
    } catch (e) {
      emit(PerangkatError(e.toString()));
    }
  }

  Future<void> _onUpload(PerangkatUploadRequested e, Emitter<PerangkatState> emit) async {
    try {
      await _repo.upload(
          namaDokumen: e.namaDokumen,
          jenisDokumen: e.jenisDokumen,
          filePath: e.filePath,
          fileName: e.fileName);
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
    emit(PerangkatLoaded(
        all: _all, filtered: _applyFilter(_filterJenis), filterJenis: _filterJenis));
  }
}
