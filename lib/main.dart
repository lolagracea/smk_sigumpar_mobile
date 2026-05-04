import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/academic_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/learning_repository.dart';
import 'data/services/academic_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/learning_service.dart';
import 'providers/academic/arsip_surat_provider.dart';
import 'providers/academic/kelas_provider.dart';
import 'providers/academic/pengumuman_provider.dart';
import 'providers/academic/siswa_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/learning/wakil_jadwal_provider.dart';
import 'providers/learning/wakil_laporan_provider.dart';
import 'providers/learning/wakil_perangkat_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  // ── Services ──────────────────────────────────────────────────────────────
  final authService = AuthService();
  final academicService = AcademicService();
  final learningService = LearningService();

  // ── Repositories ──────────────────────────────────────────────────────────
  final authRepository = AuthRepository(service: authService);
  final academicRepository = AcademicRepository(service: academicService);
  final learningRepository = LearningRepository(service: learningService);

  runApp(
    MultiProvider(
      providers: [
        // ── Core ────────────────────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (_) => AuthProvider(authRepository)),

        // ── Academic (Tata Usaha) ────────────────────────────────────────────
        ChangeNotifierProvider(
            create: (_) => KelasProvider(academicRepository)),
        ChangeNotifierProvider(
            create: (_) => SiswaProvider(academicRepository)),
        ChangeNotifierProvider(
            create: (_) => PengumumanProvider(academicRepository)),
        ChangeNotifierProvider(
            create: (_) => ArsipSuratProvider(academicRepository)),

        // ── Learning (Wakil Kepala Sekolah) ──────────────────────────────────
        ChangeNotifierProvider(
            create: (_) => WakilPerangkatProvider(learningRepository)),
        ChangeNotifierProvider(
            create: (_) => WakilJadwalProvider(learningRepository)),
        ChangeNotifierProvider(
            create: (_) => WakilLaporanProvider(learningRepository)),
      ],
      child: const MyApp(),
    ),
  );
}
