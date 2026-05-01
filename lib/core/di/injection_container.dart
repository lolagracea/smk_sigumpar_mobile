import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../theme/theme_notifier.dart';
import '../utils/secure_storage.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/academic_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/learning_repository.dart';
import '../../data/repositories/vocational_repository.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/academic_service.dart';
import '../../data/services/student_service.dart';
import '../../data/services/learning_service.dart';
import '../../data/services/vocational_service.dart';

import '../../presentation/common/providers/auth_provider.dart';
import '../../presentation/common/providers/theme_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.allowReassignment = true;

  // ─── Core ──────────────────────────────────────────────
  if (!sl.isRegistered<SecureStorage>()) {
    sl.registerLazySingleton<SecureStorage>(() => SecureStorage());
  }

  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(
          () => DioClient(
        secureStorage: sl<SecureStorage>(),
      ),
    );
  }

  if (!sl.isRegistered<ThemeNotifier>()) {
    sl.registerLazySingleton<ThemeNotifier>(() => ThemeNotifier());
  }

  // ─── Repositories / Services ───────────────────────────

  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
          () => AuthService(
        dioClient: sl<DioClient>(),
        secureStorage: sl<SecureStorage>(),
      ),
    );
  }

  if (!sl.isRegistered<AcademicRepository>()) {
    sl.registerLazySingleton<AcademicRepository>(
          () => AcademicService(
        dioClient: sl<DioClient>(),
      ),
    );
  }

  if (!sl.isRegistered<StudentRepository>()) {
    sl.registerLazySingleton<StudentRepository>(
          () => StudentService(
        dioClient: sl<DioClient>(),
      ),
    );
  }

  if (!sl.isRegistered<LearningRepository>()) {
    sl.registerLazySingleton<LearningRepository>(
          () => LearningService(
        dioClient: sl<DioClient>(),
      ),
    );
  }

  if (!sl.isRegistered<VocationalRepository>()) {
    sl.registerLazySingleton<VocationalRepository>(
          () => VocationalService(
        dioClient: sl<DioClient>(),
      ),
    );
  }

  // ─── Catatan penting ───────────────────────────────────
  // AssetService / AssetRepository sengaja tidak didaftarkan.
  // Di backend website kita, asset-service tidak digunakan.
  // Kalau nanti fitur asset ingin diaktifkan kembali, baru restore:
  // import '../../data/repositories/asset_repository.dart';
  // import '../../data/services/asset_service.dart';
  //
  // sl.registerLazySingleton<AssetRepository>(
  //   () => AssetService(dioClient: sl<DioClient>()),
  // );

  // ─── Providers ─────────────────────────────────────────

  if (!sl.isRegistered<ThemeProvider>()) {
    sl.registerLazySingleton<ThemeProvider>(
          () => ThemeProvider(
        notifier: sl<ThemeNotifier>(),
      ),
    );
  }

  sl.registerFactory<AuthProvider>(
        () => AuthProvider(
      authRepository: sl<AuthRepository>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );
}