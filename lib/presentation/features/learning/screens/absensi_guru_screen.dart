import 'package:flutter/material.dart';

class AbsensiGuruScreen extends StatelessWidget {
  const AbsensiGuruScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Guru')),
      body: const Center(
        child: Text(
          'Fitur Absensi Guru sedang dalam pengembangan',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
