import 'package:flutter/material.dart';
import '../../../data/models/siswa.dart';

class SiswaDetailPage extends StatelessWidget {
  const SiswaDetailPage({
    super.key,
    required this.siswa,
  });

  final Siswa siswa;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(siswa.nama)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: ListTile(
            title: Text(siswa.nama),
            subtitle: Text('NISN: ${siswa.nisn}\nKelas: ${siswa.kelas}'),
          ),
        ),
      ),
    );
  }
}
