import '../models/user_model.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  });

// Di auth_repository.dart, ubah signature jadi:
  Future<void> logout(String? refreshToken);

  Future<UserModel> getProfile();

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? email,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<Map<String, dynamic>> refreshToken(String refreshToken);
}
