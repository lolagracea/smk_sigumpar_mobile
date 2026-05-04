import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/common/providers/auth_provider.dart';
import 'presentation/common/providers/theme_provider.dart';
import '../../presentation/features/learning/providers/learning_provider.dart';
import 'presentation/features/academic/providers/academic_provider.dart';

class SmkSigumparApp extends StatefulWidget {
  const SmkSigumparApp({super.key});

  @override
  State<SmkSigumparApp> createState() => _SmkSigumparAppState();
}

class _SmkSigumparAppState extends State<SmkSigumparApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    // 1. Ambil AuthProvider dari Service Locator
    final authProvider = sl<AuthProvider>();

    // 2. Inisialisasi router dengan menyuntikkan authProvider
    // agar routerConfig bisa menggunakan 'refreshListenable'
    _router = AppRouter.createRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: sl<AuthProvider>(),
        ),
        // GANTI AnnouncementProvider menjadi AcademicProvider
        ChangeNotifierProvider<AcademicProvider>(
          create: (_) => sl<AcademicProvider>(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => sl<ThemeProvider>(),
        ),
        ChangeNotifierProvider<LearningProvider>(
          create: (_) => sl<LearningProvider>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'SMK Negeri 1 Sigumpar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // FORCE LIGHT THEME tetap dipertahankan sesuai permintaanmu
        themeMode: ThemeMode.light,
        // 3. Gunakan instance router yang sudah mendengarkan AuthProvider
        routerConfig: _router,
      ),
    );
  }
}