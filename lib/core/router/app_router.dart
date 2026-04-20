import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_page.dart';
import '../../features/dashboard/home_page.dart';
import '../../features/tata_usaha/kelas/kelas_page.dart';
import '../../features/tata_usaha/siswa/siswa_page.dart';
import '../../features/tata_usaha/pengumuman/pengumuman_page.dart';
import '../../features/tata_usaha/arsip_surat/arsip_page.dart';
import '../../features/shared/coming_soon_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/tata-usaha/kelas',
        builder: (context, state) => const KelasPage(),
      ),
      GoRoute(
        path: '/tata-usaha/siswa',
        builder: (context, state) => const SiswaPage(),
      ),
      GoRoute(
        path: '/tata-usaha/pengumuman',
        builder: (context, state) => const PengumumanPage(),
      ),
      GoRoute(
        path: '/tata-usaha/arsip-surat',
        builder: (context, state) => const ArsipPage(),
      ),
      GoRoute(
        path: '/coming-soon/:feature',
        builder: (context, state) => ComingSoonPage(
          title: state.pathParameters['feature'] ?? 'Fitur',
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(child: Text(state.error.toString())),
    ),
  );
}
