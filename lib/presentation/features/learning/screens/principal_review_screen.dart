import 'package:flutter/material.dart';

class PrincipalReviewScreen extends StatelessWidget {
  const PrincipalReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tinjauan Kepala Sekolah')),
      body: const Center(
        child: Text('Halaman Tinjauan Kepala Sekolah\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
