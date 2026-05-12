import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/common/providers/auth_provider.dart';
import 'presentation/common/providers/theme_provider.dart';
import 'presentation/features/learning/providers/learning_provider.dart';
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
    // Ambil AuthProvider dari Service Locator
    final authProvider = sl<AuthProvider>();

    // Inisialisasi router dengan refreshListenable → tidak balik ke login saat reload
    _router = AppRouter.createRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: sl<AuthProvider>(),
        ),
        ChangeNotifierProvider<AcademicProvider>(
          create: (_) => sl<AcademicProvider>(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => sl<ThemeProvider>(),
        ),
        ChangeNotifierProvider<LearningProvider>(
          create: (_) => sl<LearningProvider>(),
        ),
        ChangeNotifierProvider<AbsensiGuruProvider>(
          create: (_) => sl<AbsensiGuruProvider>(),
        ),
        ChangeNotifierProvider<StudentProvider>(
          create: (_) => sl<StudentProvider>(),
        ),
        ChangeNotifierProvider<AcademicProvider>(
          create: (_) => sl<AcademicProvider>(),
        ),
      ],
      // Consumer agar MaterialApp rebuild saat tema berubah (dari team lead)
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'SMK Negeri 1 Sigumpar',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            // Tema dinamis dari team lead
            themeMode: themeProvider.themeMode,
            // Router dengan refreshListenable dari HEAD → auth persist
            routerConfig: _router,
          );
        },
      ),
    );
  }
}