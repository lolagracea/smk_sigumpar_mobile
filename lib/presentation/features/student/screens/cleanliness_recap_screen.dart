import 'package:flutter/material.dart';

class CleanlinessRecapScreen extends StatelessWidget {
  const CleanlinessRecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Kebersihan')),
      body: const Center(
        child: Text('Halaman Rekap Kebersihan\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
