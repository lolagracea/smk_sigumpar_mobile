import 'package:flutter/material.dart';

class HomeroomReflectionScreen extends StatelessWidget {
  const HomeroomReflectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refleksi Wali Kelas')),
      body: const Center(
        child: Text('Halaman Refleksi Wali Kelas\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
