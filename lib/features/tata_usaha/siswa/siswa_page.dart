import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/siswa.dart';
import '../tata_usaha_provider.dart';

class SiswaPage extends StatefulWidget {
  const SiswaPage({super.key});

  @override
  State<SiswaPage> createState() => _SiswaPageState();
}

class _SiswaPageState extends State<SiswaPage> {
  final provider = TataUsahaProvider();

  @override
  void initState() {
    super.initState();
    provider.loadSiswa().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manajemen Siswa',
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.siswa.length,
              itemBuilder: (context, index) {
                final Siswa item = provider.siswa[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(item.nama),
                    subtitle: Text('NISN ${item.nisn} • ${item.kelas}'),
                  ),
                );
              },
            ),
    );
  }
}
