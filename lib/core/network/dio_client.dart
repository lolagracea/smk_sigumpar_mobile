import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_endpoints.dart';
import '../utils/secure_storage.dart';
import 'network_exceptions.dart';

class DioClient {
  late final Dio _dio;
  final SecureStorage _secureStorage;

  DioClient({required SecureStorage secureStorage})
      : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 60), // naik dari 30
        receiveTimeout: const Duration(seconds: 60), // naik dari 30
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_secureStorage, _dio),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    ]);
  }

  Dio get dio => _dio;

  // ─── GET ───────────────────────────────────────────────
  Future<Response> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw NetworkExceptions.fromDioError(e);
    }
  }

  // ─── POST ──────────────────────────────────────────────
  Future<Response> post(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw NetworkExceptions.fromDioError(e);
    }
  }

  // ─── PUT ───────────────────────────────────────────────
  Future<Response> put(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw NetworkExceptions.fromDioError(e);
    }
  }

  // ─── DELETE ────────────────────────────────────────────
  Future<Response> delete(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw NetworkExceptions.fromDioError(e);
    }
  }

  // ─── POST MULTIPART ────────────────────────────────────
  Future<Response> postFormData(
      String path, {
        required FormData formData,
      }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        options: Options(contentType: null),
      );
    } on DioException catch (e) {
      throw NetworkExceptions.fromDioError(e);
    }
  }

  // ─── PUT MULTIPART ─────────────────────────────────────
  Future<Response> putFormData(
      String path, {
        required FormData formData,
      }) async {
    try {
      return await _dio.put(
        path,
        data: formData,
        options: Options(contentType: null),
      );
    } on DioException catch (e) {
      throw NetworkExceptions.fromDioError(e);
    }
  }
}

// ─────────────────────────────────────────────────────────
// AUTH INTERCEPTOR
// ─────────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final Dio _mainDio;

  // Lock untuk mencegah multiple refresh berbarengan
  Future<String?>? _refreshFuture;

  _AuthInterceptor(this._secureStorage, this._mainDio);

  // ─── ON REQUEST ──────────────────────────────────────
  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    // ✅ HANYA bypass token & logout endpoint Keycloak.
    // Endpoint userinfo TETAP butuh Bearer token!
    if (_isKeycloakAuthRequest(options.uri.toString())) {
      return handler.next(options);
    }

    final token = await _secureStorage.getAccessToken();

    if (kDebugMode) {
      debugPrint('🔑 Token saat request: '
          '${token == null ? "NULL" : "ada (${token.substring(0, 20)}...)"}');
      debugPrint('🔑 URL: ${options.uri}');
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  // ─── ON ERROR ────────────────────────────────────────
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    // ⚠️ HANYA 401 yang trigger refresh token.
    // 403 = role tidak punya izin → refresh tidak akan menyelesaikan masalah.
    if (statusCode != 401) {
      return handler.next(err);
    }

    // Jangan refresh kalau yang error adalah token/logout endpoint sendiri
    // (mencegah infinite loop saat refresh token expired)
    if (_isKeycloakAuthRequest(err.requestOptions.uri.toString())) {
      return handler.next(err);
    }

    try {
      final newToken = await _refreshAccessToken();

      if (newToken == null) {
        return handler.next(err);
      }

      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      final response = await _mainDio.fetch(err.requestOptions);
      return handler.resolve(response);
    } catch (e) {
      return handler.next(err);
    }
  }

  // ─── REFRESH TOKEN dengan LOCK ───────────────────────
  Future<String?> _refreshAccessToken() {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    final completer = Completer<String?>();
    _refreshFuture = completer.future;

    _doRefresh().then((token) {
      completer.complete(token);
    }).catchError((e) {
      completer.complete(null);
    }).whenComplete(() {
      _refreshFuture = null;
    });

    return completer.future;
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _secureStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      await _secureStorage.clearAll();
      return null;
    }

    try {
      final refreshDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60), // ← UBAH
          receiveTimeout: const Duration(seconds: 60), // ← UBAH
        ),
      );
      final response = await refreshDio.post(
        ApiEndpoints.keycloakTokenUrl,
        data: {
          'client_id': ApiEndpoints.keycloakClientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data as Map<String, dynamic>;
      final newAccessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _secureStorage.clearAll();
        return null;
      }

      await _secureStorage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _secureStorage.saveRefreshToken(newRefreshToken);
      }

      if (kDebugMode) {
        debugPrint('🔄 Token berhasil di-refresh');
      }

      return newAccessToken;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400 || code == 401) {
        await _secureStorage.clearAll();
        if (kDebugMode) {
          debugPrint('❌ Refresh token expired/invalid → cleared storage');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Refresh gagal (network/timeout): $code');
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Refresh gagal (unknown): $e');
      }
      return null;
    }
  }

  // ─── HELPER ──────────────────────────────────────────
  /// Endpoint Keycloak yang TIDAK butuh Bearer token.
  /// userinfo TETAP butuh Bearer, jadi TIDAK masuk sini.
  bool _isKeycloakAuthRequest(String url) {
    return url.contains('/protocol/openid-connect/token') ||
        url.contains('/protocol/openid-connect/logout');
  }
}