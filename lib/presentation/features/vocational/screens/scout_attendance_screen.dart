import 'package:flutter/material.dart';
import 'pramuka/absensi_pramuka_screen.dart';

// Re-export agar router yang sudah ada tetap berfungsi
export 'pramuka/absensi_pramuka_screen.dart' show AbsensiPramukaScreen;

// Alias ScoutAttendanceScreen → AbsensiPramukaScreen
class ScoutAttendanceScreen extends StatelessWidget {
  const ScoutAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AbsensiPramukaScreen();
  }
}
