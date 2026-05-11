import 'package:dio/dio.dart';

class NetworkExceptions implements Exception {
  final String message;
  final int? statusCode;
  final NetworkExceptionType type;

  const NetworkExceptions({
    required this.message,
    required this.type,
    this.statusCode,
  });

  factory NetworkExceptions.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkExceptions(
          message: 'Koneksi timeout. Periksa jaringan Anda.',
          type: NetworkExceptionType.timeout,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        final message = data is Map ? data['message'] ?? _messageFromStatus(statusCode) : _messageFromStatus(statusCode);

        return NetworkExceptions(
          message: message,
          type: _typeFromStatus(statusCode),
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return const NetworkExceptions(
          message: 'Permintaan dibatalkan.',
          type: NetworkExceptionType.cancelled,
        );

      case DioExceptionType.connectionError:
        return const NetworkExceptions(
          message: 'Tidak dapat terhubung ke server.',
          type: NetworkExceptionType.noInternet,
        );

      default:
        return NetworkExceptions(
          message: error.message ?? 'Terjadi kesalahan tidak diketahui.',
          type: NetworkExceptionType.unknown,
        );
    }
  }

  static String _messageFromStatus(int? code) {
    switch (code) {
      case 400: return 'Permintaan tidak valid.';
      case 401: return 'Sesi habis. Silakan masuk kembali.';
      case 403: return 'Anda tidak memiliki akses.';
      case 404: return 'Data tidak ditemukan.';
      case 409: return 'Konflik data. Silakan periksa kembali.';
      case 422: return 'Data tidak valid.';
      case 500: return 'Kesalahan server. Coba lagi nanti.';
      default: return 'Terjadi kesalahan (${code ?? "?"}).';
    }
  }

  static NetworkExceptionType _typeFromStatus(int? code) {
    switch (code) {
      case 401: return NetworkExceptionType.unauthorized;
      case 403: return NetworkExceptionType.forbidden;
      case 404: return NetworkExceptionType.notFound;
      case 500:
      case 502:
      case 503: return NetworkExceptionType.serverError;
      default: return NetworkExceptionType.unknown;
    }
  }

  @override
  String toString() => 'NetworkExceptions: $message (type: $type, status: $statusCode)';
}

enum NetworkExceptionType {
  timeout,
  noInternet,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  cancelled,
  unknown,
}
