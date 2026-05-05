import 'package:flutter/material.dart';

class SummonsLetterScreen extends StatelessWidget {
  const SummonsLetterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Surat Panggilan')),
      body: const Center(
        child: Text('Halaman Surat Panggilan\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
