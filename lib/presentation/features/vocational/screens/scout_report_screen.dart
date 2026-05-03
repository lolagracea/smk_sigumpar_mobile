import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/route_names.dart';
import '../providers/vocational_provider.dart';
import '../widgets/pramuka_drawer.dart';

class ScoutReportScreen extends StatefulWidget {
  const ScoutReportScreen({super.key});

  @override
  State<ScoutReportScreen> createState() => _ScoutReportScreenState();
}

class _ScoutReportScreenState extends State<ScoutReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocationalProvider>().fetchScoutReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Laporan Kegiatan'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Buat Laporan',
            onPressed: () => _showCreateReportForm(context),
          ),
        ],
      ),
      drawer: const PramukaDrawer(currentRoute: RouteNames.scoutReport),
      body: Consumer<VocationalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(provider.error ?? 'Terjadi kesalahan'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchScoutReports(refresh: true),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (provider.scoutReports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada laporan kegiatan',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateReportForm(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Buat Laporan'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchScoutReports(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.scoutReports.length,
              itemBuilder: (context, index) {
                return _buildReportCard(provider.scoutReports[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final judul = report['judul'] ?? report['title'] ?? 'Laporan Kegiatan';
    final tanggal = report['tanggal'] ?? report['date'] ?? '-';
    final status = report['status'] ?? 'pending';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusLabel = 'Disetujui';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'Ditolak';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Menunggu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    judul,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  tanggal,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            if (report['deskripsi'] != null || report['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                report['deskripsi'] ?? report['description'] ?? '',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateReportForm(BuildContext context) {
    final provider = context.read<VocationalProvider>();
    final judulController = TextEditingController();
    final deskripsiController = TextEditingController();
    final dateController = TextEditingController(
      text: DateTime.now().toString().substring(0, 10),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buat Laporan Kegiatan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: judulController,
              decoration: InputDecoration(
                labelText: 'Judul Kegiatan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: deskripsiController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Deskripsi Kegiatan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Tanggal Kegiatan',
                suffixIcon: const Icon(Icons.calendar_today_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  dateController.text = picked.toString().substring(0, 10);
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (judulController.text.isEmpty) return;
                  final success = await provider.createScoutReport({
                    'judul': judulController.text,
                    'deskripsi': deskripsiController.text,
                    'tanggal': dateController.text,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Laporan berhasil dibuat'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Simpan Laporan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}