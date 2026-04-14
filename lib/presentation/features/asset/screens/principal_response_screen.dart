import 'package:flutter/material.dart';

class PrincipalResponseScreen extends StatelessWidget {
  const PrincipalResponseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respons Kepala Sekolah')),
      body: const Center(
        child: Text('Halaman Respons Kepala Sekolah\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
