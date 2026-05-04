import 'package:flutter/material.dart';

class ScoutClassesScreen extends StatelessWidget {
  const ScoutClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelas Pramuka')),
      body: const Center(
        child: Text('Halaman Kelas Pramuka\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
