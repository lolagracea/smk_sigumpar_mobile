import 'package:flutter/material.dart';

class TreasurerResponseScreen extends StatelessWidget {
  const TreasurerResponseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respons Bendahara')),
      body: const Center(
        child: Text('Halaman Respons Bendahara\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
