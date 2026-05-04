import 'package:flutter/material.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mata Pelajaran')),
      body: const Center(
        child: Text(
          'Fitur Mata Pelajaran sedang dalam pengembangan',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
