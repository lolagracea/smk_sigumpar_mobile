import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../theme/theme_notifier.dart';
import '../utils/secure_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/academic_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/learning_repository.dart';
import '../../data/repositories/vocational_repository.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/academic_service.dart';
import '../../data/services/student_service.dart';
import '../../data/services/learning_service.dart';
import '../../data/services/vocational_service.dart';
import '../../data/services/asset_service.dart';
import '../../presentation/common/providers/auth_provider.dart';
import '../../presentation/common/providers/theme_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {

  sl.allowReassignment = true;
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
      secureStorage: sl<SecureStorage>(), // 👇 Ditambah di sini
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

  // ─── Providers ─────────────────────────────────────────
  sl.registerLazySingleton<ThemeProvider>(
        () => ThemeProvider(notifier: sl<ThemeNotifier>()),
  );

  sl.registerFactory<AuthProvider>(
        () => AuthProvider(
      authRepository: sl<AuthRepository>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );
}