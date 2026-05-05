import 'package:flutter/material.dart';

class LoanResponseScreen extends StatelessWidget {
  const LoanResponseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respons Peminjaman')),
      body: const Center(
        child: Text('Halaman Respons Peminjaman\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
