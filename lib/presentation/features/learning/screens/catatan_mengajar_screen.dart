import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catatan_mengajar_provider.dart';

class CatatanMengajarScreen extends StatefulWidget {
  const CatatanMengajarScreen({super.key});

  @override
  State<CatatanMengajarScreen> createState() =>
      _CatatanMengajarScreenState();
}

class _CatatanMengajarScreenState extends State<CatatanMengajarScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<CatatanMengajarProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CatatanMengajarProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Mengajar')),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: p.data.length,
        itemBuilder: (_, i) {
          final item = p.data[i];

          return ListTile(
            title: Text(item['guru'] ?? '-'),
            subtitle: Text(item['catatan'] ?? '-'),
          );
        },
      ),
    );
  }
}