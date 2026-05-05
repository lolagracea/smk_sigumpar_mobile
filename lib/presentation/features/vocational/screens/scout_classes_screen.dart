import 'package:flutter/material.dart';
import 'pramuka/silabus_pramuka_screen.dart';

// Re-export agar router yang sudah ada tetap berfungsi
export 'pramuka/silabus_pramuka_screen.dart' show SilabusPramukaScreen;

// Alias ScoutClassesScreen → SilabusPramukaScreen
class ScoutClassesScreen extends StatelessWidget {
  const ScoutClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SilabusPramukaScreen();
  }
}
