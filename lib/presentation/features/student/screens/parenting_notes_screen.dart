import 'package:flutter/material.dart';

class ParentingNotesScreen extends StatelessWidget {
  const ParentingNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Parenting')),
      body: const Center(
        child: Text('Halaman Catatan Parenting\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
