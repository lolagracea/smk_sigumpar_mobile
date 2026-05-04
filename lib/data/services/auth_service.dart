import '../models/user_model.dart';

class AuthService {
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (username == 'admin' && password == 'admin') {
      return const UserModel(
        id: '1',
        username: 'admin',
        name: 'Administrator',
        roles: <String>['admin', 'tata-usaha'],
      );
    }

    throw Exception('Username atau password salah');
  }
}
