import 'package:flutter/material.dart';

class ScoutAttendanceScreen extends StatelessWidget {
  const ScoutAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Pramuka')),
      body: const Center(
        child: Text('Halaman Absensi Pramuka\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
