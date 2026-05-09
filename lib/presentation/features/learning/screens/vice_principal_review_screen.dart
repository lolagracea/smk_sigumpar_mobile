import 'package:flutter/material.dart';

class VicePrincipalReviewScreen extends StatelessWidget {
  const VicePrincipalReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tinjauan Wakasek')),
      body: const Center(
        child: Text('Halaman Tinjauan Wakasek\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
