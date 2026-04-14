import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_endpoints.dart';
import '../utils/secure_storage.dart';
import '../utils/token_helper.dart';
import 'network_exceptions.dart';

class DioClient {
  late final Dio _dio;
  final SecureStorage _secureStorage;

  DioClient({required SecureStorage secureStorage})
      : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_secureStorage),
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
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
    } on DioException catch (e) {
      throw NetworkExceptions.fromDioError(e);
    }
  }
}

// ─── Auth Interceptor ──────────────────────────────────
class _AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;

  _AuthInterceptor(this._secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Coba refresh token
      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken != null) {
          final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
          final response = await dio.post(
            ApiEndpoints.refreshToken,
            data: {'refresh_token': refreshToken},
          );
          final newToken = response.data['access_token'];
          await _secureStorage.saveAccessToken(newToken);

          // Retry request
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final clonedRequest = await dio.fetch(err.requestOptions);
          return handler.resolve(clonedRequest);
        }
      } catch (_) {
        await _secureStorage.clearAll();
      }
    }
    handler.next(err);
  }
}
