import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/pengumuman.dart';
import '../tata_usaha_provider.dart';

class PengumumanPage extends StatefulWidget {
  const PengumumanPage({super.key});

  @override
  State<PengumumanPage> createState() => _PengumumanPageState();
}

class _PengumumanPageState extends State<PengumumanPage> {
  final provider = TataUsahaProvider();

  @override
  void initState() {
    super.initState();
    provider.loadPengumuman().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pengumuman',
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.pengumuman.length,
              itemBuilder: (context, index) {
                final Pengumuman item = provider.pengumuman[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.campaign_outlined),
                    title: Text(item.judul),
                    subtitle: Text(
                      '${item.isi}\n${AppDateUtils.simpleDate(item.tanggal)}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
