import 'package:flutter/material.dart';

class TeachersScreen extends StatelessWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Guru')),
      body: const Center(
        child: Text(
          'Halaman Data Guru\n(Dalam Pengembangan)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
