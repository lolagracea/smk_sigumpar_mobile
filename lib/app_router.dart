import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/tata_usaha/arsip_surat/arsip_surat_screen.dart';
import 'features/tata_usaha/kelas/kelas_screen.dart';
import 'features/tata_usaha/pengumuman/pengumuman_screen.dart';
import 'features/tata_usaha/siswa/siswa_screen.dart';

// Wakil Kepala Sekolah  <-- import baru
import 'features/wakil_kepsek/wakasek_dashboard_screen.dart';
import 'features/wakil_kepsek/perangkat/perangkat_screen.dart';
import 'features/wakil_kepsek/evaluasi_guru/evaluasi_guru_screen.dart';
import 'features/wakil_kepsek/catatan_mengajar/catatan_mengajar_screen.dart';
import 'providers/wakasek/perangkat_provider.dart';
import 'providers/wakasek/evaluasi_guru_provider.dart';
import 'providers/wakasek/catatan_mengajar_provider.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // ─── Tata Usaha ───────────────────────────────────────
      GoRoute(
        path: '/kelas',
        builder: (context, state) => const KelasScreen(),
      ),
      GoRoute(
        path: '/siswa',
        builder: (context, state) => const SiswaScreen(),
      ),
      GoRoute(
        path: '/pengumuman',
        builder: (context, state) => const PengumumanScreen(),
      ),
      GoRoute(
        path: '/arsip-surat',
        builder: (context, state) => const ArsipSuratScreen(),
      ),

      // ─── Wakil Kepala Sekolah ─────────────────────────────
      GoRoute(
        path: '/wakasek',
        builder: (context, state) => const WakasekDashboardScreen(),
      ),
      GoRoute(
        path: '/wakasek/perangkat',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => PerangkatProvider(
            context.read(),
          ),
          child: const PerangkatScreen(),
        ),
      ),
      GoRoute(
        path: '/wakasek/evaluasi-guru',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => EvaluasiGuruProvider(
            context.read(),
          ),
          child: const EvaluasiGuruScreen(),
        ),
      ),
      GoRoute(
        path: '/wakasek/catatan-mengajar',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => CatatanMengajarProvider(
            context.read(),
          ),
          child: const CatatanMengajarScreen(),
        ),
      ),
    ],
  );
}