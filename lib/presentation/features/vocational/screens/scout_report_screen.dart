import 'package:flutter/material.dart';
import 'pramuka/laporan_kegiatan_pramuka_screen.dart';

// Re-export agar router yang sudah ada tetap berfungsi
export 'pramuka/laporan_kegiatan_pramuka_screen.dart' show LaporanKegiatanPramukaScreen;

// Alias ScoutReportScreen → LaporanKegiatanPramukaScreen
class ScoutReportScreen extends StatelessWidget {
  const ScoutReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LaporanKegiatanPramukaScreen();
  }
}
