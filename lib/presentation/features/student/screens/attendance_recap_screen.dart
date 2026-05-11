import 'package:flutter/material.dart';

class AttendanceRecapScreen extends StatelessWidget {
  const AttendanceRecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Kehadiran')),
      body: const Center(
        child: Text('Halaman Rekap Kehadiran\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
