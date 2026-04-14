import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthService implements AuthRepository {
  final DioClient _dioClient;

  AuthService({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.login,
      data: {'username': username, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> logout() async {
    await _dioClient.post(ApiEndpoints.logout);
  }

  @override
  Future<UserModel> getProfile() async {
    final response = await _dioClient.get(ApiEndpoints.profile);
    return UserModel.fromJson(response.data['data']);
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;
    await _dioClient.put('${ApiEndpoints.profile}/update', data: data);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dioClient.post(
      '${ApiEndpoints.profile}/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dioClient.post(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': refreshToken},
    );
    return response.data as Map<String, dynamic>;
  }
}
