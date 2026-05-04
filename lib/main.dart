import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/academic_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/wakasek_repository.dart'; // <-- TAMBAH
import 'data/services/academic_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/wakasek_service.dart';          // <-- TAMBAH
import 'providers/academic/arsip_surat_provider.dart';
import 'providers/academic/kelas_provider.dart';
import 'providers/academic/pengumuman_provider.dart';
import 'providers/academic/siswa_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  final authService = AuthService();
  final academicService = AcademicService();
  final wakasekService = WakasekService(); // <-- TAMBAH

  final authRepository = AuthRepository(service: authService);
  final academicRepository = AcademicRepository(service: academicService);
  final wakasekRepository = WakasekRepository(service: wakasekService); // <-- TAMBAH

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
        // Wakasek repository tersedia sebagai Provider biasa
        // supaya GoRouter bisa akses via context.read()
        Provider<WakasekRepository>.value(value: wakasekRepository), // <-- TAMBAH
      ],
      child: const MyApp(),
    ),
  );
}
