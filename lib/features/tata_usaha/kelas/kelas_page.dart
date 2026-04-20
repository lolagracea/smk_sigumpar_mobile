import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/kelas.dart';
import '../tata_usaha_provider.dart';
import 'kelas_form.dart';

class KelasPage extends StatefulWidget {
  const KelasPage({super.key});

  @override
  State<KelasPage> createState() => _KelasPageState();
}

class _KelasPageState extends State<KelasPage> {
  final provider = TataUsahaProvider();

  @override
  void initState() {
    super.initState();
    provider.loadKelas().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manajemen Kelas',
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const KelasForm(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.kelas.length,
              itemBuilder: (context, index) {
                final Kelas item = provider.kelas[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.class_),
                    title: Text(item.nama),
                    subtitle: Text('Tingkat ${item.tingkat} • Wali: ${item.waliKelas ?? '-'}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
    );
  }
}
