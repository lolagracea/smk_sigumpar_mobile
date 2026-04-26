import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smk_sigumpar/core/di/injection_container.dart' as di;
import 'package:smk_sigumpar/core/router/app_router.dart';
import 'package:smk_sigumpar/presentation/common/providers/auth_provider.dart';
import 'package:smk_sigumpar/core/theme/theme_notifier.dart';
import 'package:smk_sigumpar/core/theme/app_theme.dart';
import 'package:smk_sigumpar/presentation/common/providers/theme_provider.dart';

class SmkSigumparApp extends StatelessWidget {
  const SmkSigumparApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengambil instance AuthProvider yang sudah diinisialisasi di main.dart melalui GetIt
    final authProvider = di.sl<AuthProvider>();

    // Membuat instance router dengan menyertakan authProvider
    // agar properti refreshListenable dapat memicu redirect otomatis
    final router = AppRouter.createRouter(authProvider);

    return MultiProvider(
      providers: [
        // Provider autentikasi
        ChangeNotifierProvider.value(value: authProvider),

        // Provider tema bawaan core (jika masih dipakai)
        ChangeNotifierProvider(create: (_) => di.sl<ThemeNotifier>()),

        // 👇 TAMBAHKAN BARIS INI UNTUK MEMPERBAIKI ERROR DI PROFILE SCREEN 👇
        // Jika ThemeProvider kamu didaftarkan di GetIt (di.sl):
        ChangeNotifierProvider(create: (_) => di.sl<ThemeProvider>()),
        // ATAU jika tidak menggunakan GetIt, cukup panggil constructor-nya:
        // ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp.router(
            title: 'SMK N 1 Sigumpar',
            debugShowCheckedModeBanner: false,
            // Mengintegrasikan routerConfig dengan GoRouter yang sudah dibuat
            routerConfig: router,
            // Konfigurasi tema aplikasi
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.themeMode,
          );
        },
      ),
    );
  }
}