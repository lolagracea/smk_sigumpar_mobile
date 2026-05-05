import 'package:flutter/material.dart';

class LearningDeviceScreen extends StatelessWidget {
  const LearningDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perangkat Pembelajaran')),
      body: const Center(
        child: Text('Halaman Perangkat Pembelajaran\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
