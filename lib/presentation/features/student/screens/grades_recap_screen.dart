import 'package:flutter/material.dart';

class GradesRecapScreen extends StatelessWidget {
  const GradesRecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Nilai')),
      body: const Center(
        child: Text('Halaman Rekap Nilai\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
