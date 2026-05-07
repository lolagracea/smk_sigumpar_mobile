import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/route_names.dart';
import '../../../../../core/di/injection_container.dart';
import '../../providers/vice_principal_provider.dart';

class WakilDashboardScreen extends StatelessWidget {
  const WakilDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<VicePrincipalProvider>()..loadDashboard(),
      child: const _WakilDashboardView(),
    );
  }
}

class _WakilDashboardView extends StatelessWidget {
  const _WakilDashboardView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VicePrincipalProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Wakil Kepala Sekolah'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<VicePrincipalProvider>().loadDashboard(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Monitoring Learning Service',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pantau jadwal, absensi guru, perangkat pembelajaran, parenting, dan laporan ringkas.',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.isError)
              _ErrorBox(
                message: provider.errorMessage ?? 'Gagal memuat data',
                onRetry: () =>
                    context.read<VicePrincipalProvider>().loadDashboard(),
              )
            else ...[
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _SummaryCard(
                      label: 'Jadwal',
                      value: provider.totalJadwal.toString(),
                      icon: Icons.schedule_outlined,
                      onTap: () => context.go(RouteNames.wakilJadwal),
                    ),
                    _SummaryCard(
                      label: 'Absensi Guru',
                      value: provider.totalAbsensiGuru.toString(),
                      icon: Icons.fact_check_outlined,
                      onTap: () => context.go(RouteNames.wakilAbsensiGuru),
                    ),
                    _SummaryCard(
                      label: 'Perangkat',
                      value: provider.totalPerangkat.toString(),
                      icon: Icons.folder_copy_outlined,
                      onTap: () => context.go(RouteNames.wakilPerangkat),
                    ),
                    _SummaryCard(
                      label: 'Parenting',
                      value: provider.totalParenting.toString(),
                      icon: Icons.family_restroom_outlined,
                      onTap: () => context.go(RouteNames.wakilParenting),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.assessment_outlined),
                    ),
                    title: const Text('Laporan Ringkas'),
                    subtitle: const Text(
                      'Lihat rekap singkat monitoring wakil kepala sekolah.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(RouteNames.wakilLaporan),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: const Color(0xFF2563EB)),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(message),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}