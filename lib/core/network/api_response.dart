import 'package:equatable/equatable.dart';

class ApiResponse<T> extends Equatable {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? meta;
  final List<String>? errors;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.meta,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      meta: json['meta'],
      errors: json['errors'] != null
          ? List<String>.from(json['errors'])
          : null,
    );
  }

  bool get isSuccess => success && data != null;

  @override
  List<Object?> get props => [success, message, data, meta, errors];
}

// ─── Wrapper untuk list response ───────────────────────
class PaginatedResponse<T> extends Equatable {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasNextPage => currentPage < lastPage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final data = json['data'] as Map<String, dynamic>;
    return PaginatedResponse<T>(
      items: (data['data'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      currentPage: data['current_page'] ?? 1,
      lastPage: data['last_page'] ?? 1,
      perPage: data['per_page'] ?? 15,
      total: data['total'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [items, currentPage, lastPage, perPage, total];
}
