import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/arsip_surat.dart';
import '../tata_usaha_provider.dart';
import 'arsip_form.dart';

class ArsipPage extends StatefulWidget {
  const ArsipPage({super.key});

  @override
  State<ArsipPage> createState() => _ArsipPageState();
}

class _ArsipPageState extends State<ArsipPage> {
  final provider = TataUsahaProvider();

  @override
  void initState() {
    super.initState();
    provider.loadArsip().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Arsip Surat',
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const ArsipForm(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.arsip.length,
              itemBuilder: (context, index) {
                final ArsipSurat item = provider.arsip[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_copy_outlined),
                    title: Text(item.perihal),
                    subtitle: Text('Nomor surat: ${item.nomorSurat}'),
                  ),
                );
              },
            ),
    );
  }
}
