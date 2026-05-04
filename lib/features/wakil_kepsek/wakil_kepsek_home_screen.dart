import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learning/wakil_laporan_provider.dart';
import '../../shared/shell_scaffold.dart';
import '../../shared/widgets/loading_widget.dart';

class WakilKepsekHomeScreen extends StatefulWidget {
  const WakilKepsekHomeScreen({super.key});

  @override
  State<WakilKepsekHomeScreen> createState() => _WakilKepsekHomeScreenState();
}

class _WakilKepsekHomeScreenState extends State<WakilKepsekHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final token = context.read<AuthProvider>().currentUser?.token ?? '';
    context.read<WakilLaporanProvider>().loadLaporan(token);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final laporanProv = context.watch<WakilLaporanProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return ShellScaffold(
      title: 'Wakil Kepala Sekolah',
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          children: <Widget>[
            // ── Kartu Sambutan ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
                        child: Icon(Icons.school,
                            color: colorScheme.onPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Selamat datang,',
                              style: TextStyle(
                                color: colorScheme.onPrimary.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              auth.currentUser?.name ?? 'Wakil Kepsek',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SMK Negeri 1 Sigumpar',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Panel Monitoring Wakil Kepala Sekolah',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Ringkasan Data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),

            // ── Statistik Ringkas ─────────────────────────────────────────
            if (laporanProv.isLoading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: LoadingWidget()))
            else if (laporanProv.error != null)
              _ErrorCard(message: laporanProv.error!, onRetry: _loadData)
            else if (laporanProv.laporan != null) ...<Widget>[
              _StatGrid(laporan: laporanProv.laporan!),
              const SizedBox(height: 8),
              _PerangkatProgressCard(laporan: laporanProv.laporan!),
            ],

            const SizedBox(height: 20),
            Text(
              'Menu Utama',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),

            // ── Menu Cards ───────────────────────────────────────────────
            _MenuCard(
              icon: Icons.assignment_outlined,
              title: 'Perangkat Pembelajaran',
              subtitle: 'Monitor & kelola perangkat tiap guru',
              color: Colors.indigo,
              onTap: () => context.push(RouteConstants.wakilPerangkatList),
            ),
            const SizedBox(height: 10),
            _MenuCard(
              icon: Icons.calendar_month_outlined,
              title: 'Jadwal Mengajar',
              subtitle: 'Monitor jadwal & deteksi bentrok',
              color: Colors.teal,
              onTap: () => context.push(RouteConstants.wakilJadwal),
            ),
            const SizedBox(height: 10),
            _MenuCard(
              icon: Icons.bar_chart_outlined,
              title: 'Rekap Jadwal per Hari',
              subtitle: 'Total jam, guru, dan kelas per hari',
              color: Colors.orange,
              onTap: () => context.push(RouteConstants.wakilRekapJadwal),
            ),
            const SizedBox(height: 10),
            _MenuCard(
              icon: Icons.summarize_outlined,
              title: 'Laporan Ringkas',
              subtitle: 'Ringkasan data keseluruhan sekolah',
              color: Colors.purple,
              onTap: () => context.push(RouteConstants.wakilLaporan),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Widget: Stat Grid ────────────────────────────────────────────────────────
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.laporan});
  final dynamic laporan;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: <Widget>[
        _StatTile(
            label: 'Total Guru',
            value: '${laporan.totalGuru}',
            icon: Icons.people_outline,
            color: Colors.blue),
        _StatTile(
            label: 'Total Kelas',
            value: '${laporan.totalKelas}',
            icon: Icons.class_outlined,
            color: Colors.green),
        _StatTile(
            label: 'Jam Jadwal',
            value: '${laporan.totalJamJadwal}',
            icon: Icons.schedule_outlined,
            color: Colors.teal),
        _StatTile(
            label: 'Parenting Log',
            value: '${laporan.totalParenting}',
            icon: Icons.family_restroom_outlined,
            color: Colors.pink),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(value,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(label,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget: Progress Perangkat ───────────────────────────────────────────────
class _PerangkatProgressCard extends StatelessWidget {
  const _PerangkatProgressCard({required this.laporan});
  final dynamic laporan;

  @override
  Widget build(BuildContext context) {
    final pct = (laporan.persentasePerangkat * 100).toStringAsFixed(1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Perangkat Lengkap',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text('$pct%',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: laporan.persentasePerangkat,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  laporan.persentasePerangkat >= 0.8
                      ? Colors.green
                      : laporan.persentasePerangkat >= 0.5
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${laporan.perangkatLengkap} lengkap dari ${laporan.totalPerangkat} total',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget: Menu Card ────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing:
            const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

// ─── Widget: Error Card ───────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(message,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
