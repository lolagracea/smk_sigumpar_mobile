import 'package:flutter/material.dart';

class TeachingNotesScreen extends StatelessWidget {
  const TeachingNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Mengajar')),
      body: const Center(
        child: Text('Halaman Catatan Mengajar\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
