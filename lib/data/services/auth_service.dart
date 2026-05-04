import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../../core/utils/secure_storage.dart';

class AuthService implements AuthRepository {
  final DioClient _dioClient;
  final SecureStorage _secureStorage;

  AuthService({
    required DioClient dioClient,
    required SecureStorage secureStorage,
  })  : _dioClient = dioClient,
        _secureStorage = secureStorage;

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final dio = Dio();
    final response = await dio.post(
      ApiEndpoints.keycloakTokenUrl,
      data: {
        'client_id': ApiEndpoints.keycloakClientId,
        'grant_type': 'password',
        'username': username,
        'password': password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        final dio = Dio();
        await dio.post(
          ApiEndpoints.keycloakLogoutUrl,
          data: {
            'client_id': ApiEndpoints.keycloakClientId,
            'refresh_token': refreshToken,
          },
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
          ),
        );
      } catch (_) {}
    }
  }

  @override
  Future<UserModel> getProfile() async {
    final dio = Dio();
    final token = await _secureStorage.getAccessToken();
    final response = await dio.get(
      ApiEndpoints.keycloakUserInfoUrl,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {}

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final dio = Dio();
    final response = await dio.post(
      ApiEndpoints.keycloakTokenUrl,
      data: {
        'client_id': ApiEndpoints.keycloakClientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data as Map<String, dynamic>;
  }
}
