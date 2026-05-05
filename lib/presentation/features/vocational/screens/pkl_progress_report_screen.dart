import 'package:flutter/material.dart';

class PklProgressReportScreen extends StatelessWidget {
  const PklProgressReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Kemajuan PKL')),
      body: const Center(
        child: Text('Halaman Laporan Kemajuan PKL\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
