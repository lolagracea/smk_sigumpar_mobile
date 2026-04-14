import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      body: const Center(
        child: Text(
          'Halaman Pengumuman\n(Dalam Pengembangan)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
