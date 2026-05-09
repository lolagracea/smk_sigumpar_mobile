import 'package:flutter/material.dart';

class TeacherEvaluationScreen extends StatelessWidget {
  const TeacherEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluasi Guru')),
      body: const Center(
        child: Text('Halaman Evaluasi Guru\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
