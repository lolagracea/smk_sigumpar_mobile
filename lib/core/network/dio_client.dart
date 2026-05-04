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
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      // Coba refresh token langsung ke Keycloak
      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken != null) {
          final dio = Dio(); // Gunakan instance Dio baru tanpa interceptor agar tidak terjadi loop
          final response = await dio.post(
            'http://10.0.2.2:8080/realms/smk-sigumpar/protocol/openid-connect/token',
            data: {
              'client_id': 'smk-sigumpar',
              'grant_type': 'refresh_token',
              'refresh_token': refreshToken,
            },
            options: Options(contentType: Headers.formUrlEncodedContentType),
          );

          final newToken = response.data['access_token'];
          await _secureStorage.saveAccessToken(newToken);

          // Retry request semula yang ditolak tadi dengan Token baru
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
