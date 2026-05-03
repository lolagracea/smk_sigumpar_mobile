import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/route_names.dart';
import '../providers/vocational_provider.dart';
import '../widgets/pramuka_drawer.dart';

class ScoutClassesScreen extends StatefulWidget {
  const ScoutClassesScreen({super.key});

  @override
  State<ScoutClassesScreen> createState() => _ScoutClassesScreenState();
}

class _ScoutClassesScreenState extends State<ScoutClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocationalProvider>().fetchScoutClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Kelas Pramuka'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const PramukaDrawer(currentRoute: RouteNames.scoutClasses),
      body: Consumer<VocationalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return _buildErrorState(provider.error, () {
              provider.fetchScoutClasses(refresh: true);
            });
          }

          if (provider.scoutClasses.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchScoutClasses(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.scoutClasses.length,
              itemBuilder: (context, index) {
                final kelas = provider.scoutClasses[index];
                return _buildClassCard(kelas);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> kelas) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.groups_rounded, color: Color(0xFF1565C0)),
        ),
        title: Text(
          kelas['nama'] ?? kelas['name'] ?? 'Regu Pramuka',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Anggota: ${kelas['jumlah_anggota'] ?? kelas['member_count'] ?? '-'}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Belum ada kelas pramuka',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Data kelas akan muncul di sini',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            error ?? 'Terjadi kesalahan',
            style: TextStyle(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}