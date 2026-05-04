import 'package:get_it/get_it.dart';
import 'package:smk_sigumpar/core/network/dio_client.dart';
import 'package:smk_sigumpar/core/theme/theme_notifier.dart';
import 'package:smk_sigumpar/core/utils/secure_storage.dart';
import 'package:smk_sigumpar/data/repositories/auth_repository.dart';
import 'package:smk_sigumpar/data/repositories/academic_repository.dart';
import 'package:smk_sigumpar/data/repositories/student_repository.dart';
import 'package:smk_sigumpar/data/repositories/learning_repository.dart';
import 'package:smk_sigumpar/data/repositories/vocational_repository.dart';
import 'package:smk_sigumpar/data/repositories/asset_repository.dart';
import 'package:smk_sigumpar/data/services/auth_service.dart';
import 'package:smk_sigumpar/data/services/academic_service.dart';
import 'package:smk_sigumpar/data/services/student_service.dart';
import 'package:smk_sigumpar/data/services/learning_service.dart';
import 'package:smk_sigumpar/data/services/vocational_service.dart';
import 'package:smk_sigumpar/data/services/asset_service.dart';
import 'package:smk_sigumpar/presentation/common/providers/auth_provider.dart';
import 'package:smk_sigumpar/presentation/common/providers/theme_provider.dart';
import 'package:smk_sigumpar/presentation/features/learning/providers/absensi_guru_provider.dart';
import 'package:smk_sigumpar/presentation/features/student/providers/student_provider.dart';
import 'package:smk_sigumpar/presentation/features/academic/providers/academic_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ─── Core ──────────────────────────────────────────────
  sl.registerLazySingleton<SecureStorage>(() => SecureStorage());

  sl.registerLazySingleton<DioClient>(
        () => DioClient(secureStorage: sl<SecureStorage>()),
  );

  sl.registerLazySingleton<ThemeNotifier>(() => ThemeNotifier());

  // ─── Repositories ──────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
        () => AuthService(
      dioClient: sl<DioClient>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );

  sl.registerLazySingleton<AcademicRepository>(
        () => AcademicService(dioClient: sl<DioClient>()),
  );

  sl.registerLazySingleton<StudentRepository>(
        () => StudentService(dioClient: sl<DioClient>()),
  );

  sl.registerLazySingleton<LearningRepository>(
        () => LearningService(dioClient: sl<DioClient>()),
  );

  sl.registerLazySingleton<VocationalRepository>(
        () => VocationalService(dioClient: sl<DioClient>()),
  );

  sl.registerLazySingleton<AssetRepository>(
        () => AssetService(dioClient: sl<DioClient>()),
  );

  // ─── Providers (Singleton) ─────────────────────────────
  sl.registerLazySingleton<ThemeProvider>(
        () => ThemeProvider(notifier: sl<ThemeNotifier>()),
  );

  sl.registerLazySingleton<AuthProvider>(
        () => AuthProvider(
      authRepository: sl<AuthRepository>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );

  // ─── Providers (Factory — fresh state per screen) ──────
  sl.registerFactory<AbsensiGuruProvider>(
        () => AbsensiGuruProvider(repository: sl<LearningRepository>()),
  );

  sl.registerFactory<StudentProvider>(
        () => StudentProvider(repository: sl<StudentRepository>()),
  );

  sl.registerFactory<AcademicProvider>(
        () => AcademicProvider(repository: sl<AcademicRepository>()),
  );
}