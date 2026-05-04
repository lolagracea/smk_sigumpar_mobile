import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/common/providers/auth_provider.dart';
import 'presentation/common/providers/theme_provider.dart';
import 'presentation/features/learning/providers/absensi_guru_provider.dart';

class SmkSigumparApp extends StatelessWidget {
  const SmkSigumparApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
      // ⚠️ PERBAIKAN: Gunakan Consumer agar MaterialApp rebuild saat tema berubah
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'SMK Negeri 1 Sigumpar',
            debugShowCheckedModeBanner: false,

            // Konfigurasi Tema
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme, // Pastikan ini ada di app_theme.dart Anda

            // ⚠️ PERBAIKAN: Gunakan themeMode dinamis dari Provider
            themeMode: themeProvider.themeMode,

            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}