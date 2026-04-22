import 'package:go_router/go_router.dart';

import 'data/models/wakil_kepsek_model.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/tata_usaha/arsip_surat/arsip_surat_screen.dart';
import 'features/tata_usaha/kelas/kelas_screen.dart';
import 'features/tata_usaha/pengumuman/pengumuman_screen.dart';
import 'features/tata_usaha/siswa/siswa_screen.dart';

// ── Wakil Kepsek ──────────────────────────────────────────────────────────────
import 'features/wakil_kepsek/wakil_kepsek_home_screen.dart';
import 'features/wakil_kepsek/perangkat/perangkat_guru_list_screen.dart';
import 'features/wakil_kepsek/perangkat/perangkat_guru_detail_screen.dart';
import 'features/wakil_kepsek/jadwal/jadwal_monitoring_screen.dart';
import 'features/wakil_kepsek/jadwal/rekap_jadwal_screen.dart';
import 'features/wakil_kepsek/laporan/laporan_ringkas_screen.dart';

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

      // ── Tata Usaha ────────────────────────────────────────────────────────
      GoRoute(
        path: '/tata-usaha/kelas',
        builder: (context, state) => const KelasScreen(),
      ),
      GoRoute(
        path: '/tata-usaha/siswa',
        builder: (context, state) => const SiswaScreen(),
      ),
      GoRoute(
        path: '/tata-usaha/pengumuman',
        builder: (context, state) => const PengumumanScreen(),
      ),
      GoRoute(
        path: '/tata-usaha/arsip-surat',
        builder: (context, state) => const ArsipSuratScreen(),
      ),

      // ── Wakil Kepala Sekolah ──────────────────────────────────────────────
      GoRoute(
        path: '/wakil-kepsek',
        builder: (context, state) => const WakilKepsekHomeScreen(),
      ),
      GoRoute(
        path: '/wakil-kepsek/perangkat',
        builder: (context, state) => const PerangkatGuruListScreen(),
      ),
      GoRoute(
        path: '/wakil-kepsek/perangkat/:guruId',
        builder: (context, state) {
          final guruId = int.tryParse(state.pathParameters['guruId'] ?? '') ?? 0;
          final extra = state.extra as GuruPerangkatModel?;
          return PerangkatGuruDetailScreen(
            guruId: guruId,
            guruInfo: extra,
          );
        },
      ),
      GoRoute(
        path: '/wakil-kepsek/jadwal',
        builder: (context, state) => const JadwalMonitoringScreen(),
      ),
      GoRoute(
        path: '/wakil-kepsek/jadwal/rekap',
        builder: (context, state) => const RekapJadwalScreen(),
      ),
      GoRoute(
        path: '/wakil-kepsek/laporan',
        builder: (context, state) => const LaporanRingkasScreen(),
      ),
    ],
  );
}
