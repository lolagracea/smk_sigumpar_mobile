import 'package:flutter/material.dart';

class ScoutReportScreen extends StatelessWidget {
  const ScoutReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Pramuka')),
      body: const Center(
        child: Text('Halaman Laporan Pramuka\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
