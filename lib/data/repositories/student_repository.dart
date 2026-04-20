import '../remote/student_api.dart';

class StudentRepository {
  StudentRepository(this._api);
  final StudentApi _api;

  Future<void> ping() => _api.getRingkasan();
}
