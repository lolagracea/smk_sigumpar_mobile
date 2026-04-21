import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  Future<UserModel> login({
    required String username,
    required String password,
  }) {
    return _service.login(username: username, password: password);
  }
}
