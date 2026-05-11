import 'package:flutter/material.dart';

class SubmissionInfoScreen extends StatelessWidget {
  const SubmissionInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Info Pengajuan')),
      body: const Center(
        child: Text('Halaman Info Pengajuan\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
