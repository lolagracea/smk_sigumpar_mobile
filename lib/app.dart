import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/common/providers/auth_provider.dart';
import 'presentation/common/providers/theme_provider.dart';
import 'presentation/features/learning/providers/absensi_guru_provider.dart';
import 'presentation/features/academic/providers/announcement_provider.dart';

class SmkSigumparApp extends StatelessWidget {
  const SmkSigumparApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AnnouncementProvider>(
          create: (_) => sl<AnnouncementProvider>(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => sl<ThemeProvider>(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => sl<AuthProvider>(),
        ),
        ChangeNotifierProvider<AbsensiGuruProvider>(
          create: (_) => sl<AbsensiGuruProvider>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'SMK Negeri 1 Sigumpar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // ⚠️ FORCE LIGHT THEME — biar UI consistent dengan mockup
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
