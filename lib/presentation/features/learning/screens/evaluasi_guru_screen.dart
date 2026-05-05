import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/evaluasi_guru_provider.dart';

class EvaluasiGuruScreen extends StatefulWidget {
  const EvaluasiGuruScreen({super.key});

  @override
  State<EvaluasiGuruScreen> createState() => _EvaluasiGuruScreenState();
}

class _EvaluasiGuruScreenState extends State<EvaluasiGuruScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<EvaluasiGuruProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EvaluasiGuruProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Evaluasi Guru')),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: p.data.length,
        itemBuilder: (_, i) {
          final item = p.data[i];

          return ListTile(
            title: Text(item['guru'] ?? '-'),
            subtitle: Text('Nilai: ${item['nilai'] ?? '-'}'),
          );
        },
      ),
    );
  }
}