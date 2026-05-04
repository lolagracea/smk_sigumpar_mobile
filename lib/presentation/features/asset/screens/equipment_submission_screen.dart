import 'package:flutter/material.dart';

class EquipmentSubmissionScreen extends StatelessWidget {
  const EquipmentSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Peralatan')),
      body: const Center(
        child: Text('Halaman Pengajuan Peralatan\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
