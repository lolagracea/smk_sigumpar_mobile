import 'package:flutter/material.dart';

class PklLocationReportScreen extends StatelessWidget {
  const PklLocationReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Lokasi PKL')),
      body: const Center(
        child: Text('Halaman Laporan Lokasi PKL\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
