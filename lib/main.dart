import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/academic_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/academic_service.dart';
import 'data/services/auth_service.dart';
import 'providers/academic/arsip_surat_provider.dart';
import 'providers/academic/kelas_provider.dart';
import 'providers/academic/pengumuman_provider.dart';
import 'providers/academic/siswa_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  final authService = AuthService();
  final academicService = AcademicService();

  final authRepository = AuthRepository(service: authService);
  final academicRepository = AcademicRepository(service: academicService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => KelasProvider(academicRepository)),
        ChangeNotifierProvider(create: (_) => SiswaProvider(academicRepository)),
        ChangeNotifierProvider(
          create: (_) => PengumumanProvider(academicRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ArsipSuratProvider(academicRepository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}