import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/common/providers/auth_provider.dart';
import 'presentation/common/providers/theme_provider.dart';
import 'presentation/features/vocational/providers/vocational_provider.dart';

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
        ChangeNotifierProvider<VocationalProvider>(
          create: (_) => sl<VocationalProvider>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'SMK Negeri 1 Sigumpar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}