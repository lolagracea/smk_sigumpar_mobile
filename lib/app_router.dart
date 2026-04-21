import 'package:go_router/go_router.dart';

import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/tata_usaha/arsip_surat/arsip_surat_screen.dart';
import 'features/tata_usaha/kelas/kelas_screen.dart';
import 'features/tata_usaha/pengumuman/pengumuman_screen.dart';
import 'features/tata_usaha/siswa/siswa_screen.dart';

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
    ],
  );
}