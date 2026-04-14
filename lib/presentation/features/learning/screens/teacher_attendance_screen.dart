import 'package:flutter/material.dart';

class TeacherAttendanceScreen extends StatelessWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kehadiran Guru')),
      body: const Center(
        child: Text('Halaman Kehadiran Guru\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
