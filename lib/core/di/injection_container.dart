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
import '../../presentation/features/learning/providers/absensi_guru_provider.dart';
import '../../presentation/features/learning/providers/perangkat_provider.dart';
import '../../presentation/features/learning/providers/evaluasi_guru_provider.dart';
import '../../presentation/features/learning/providers/catatan_mengajar_provider.dart';// ← BARU

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
// ─── WAKIL KEPALA SEKOLAH PROVIDERS ─────────────────────
  sl.registerFactory<PerangkatProvider>(
        () => PerangkatProvider(sl<LearningRepository>()),
  );

  sl.registerFactory<EvaluasiGuruProvider>(
        () => EvaluasiGuruProvider(sl<LearningRepository>()),
  );

  sl.registerFactory<CatatanMengajarProvider>(
        () => CatatanMengajarProvider(sl<LearningRepository>()),
  );
  // ─── Providers (Factory — fresh state per screen) ──────
  sl.registerFactory<AbsensiGuruProvider>(
        () => AbsensiGuruProvider(repository: sl<LearningRepository>()),
  );
}