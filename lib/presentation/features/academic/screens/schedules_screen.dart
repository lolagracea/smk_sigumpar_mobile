import 'package:flutter/material.dart';

class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Pelajaran')),
      body: const Center(
        child: Text(
          'Halaman Jadwal Pelajaran\n(Dalam Pengembangan)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
