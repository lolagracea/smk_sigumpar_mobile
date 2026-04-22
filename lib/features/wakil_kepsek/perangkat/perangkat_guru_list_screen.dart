import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_constants.dart';
import '../../../data/models/wakil_kepsek_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning/wakil_perangkat_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';

class PerangkatGuruListScreen extends StatefulWidget {
  const PerangkatGuruListScreen({super.key});

  @override
  State<PerangkatGuruListScreen> createState() =>
      _PerangkatGuruListScreenState();
}

class _PerangkatGuruListScreenState extends State<PerangkatGuruListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final token = context.read<AuthProvider>().currentUser?.token ?? '';
    context.read<WakilPerangkatProvider>().loadDaftarGuru(token);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WakilPerangkatProvider>();

    final filtered = _query.isEmpty
        ? prov.daftarGuru
        : prov.daftarGuru
            .where((g) =>
                g.namaLengkap.toLowerCase().contains(_query.toLowerCase()) ||
                g.mataPelajaran.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return ShellScaffold(
      title: 'Perangkat Pembelajaran',
      body: Column(
        children: <Widget>[
          // ── Search Bar ─────────────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Cari nama guru atau mata pelajaran...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),

          if (prov.isLoadingDaftar) ...<Widget>[
            const Expanded(child: LoadingWidget()),
          ] else if (prov.errorDaftar != null) ...<Widget>[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(prov.errorDaftar!,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...<Widget>[
            // ── Summary chips ──────────────────────────────────────────
            _SummaryRow(list: prov.daftarGuru),
            const SizedBox(height: 10),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _load(),
                child: filtered.isEmpty
                    ? const Center(child: Text('Tidak ada data guru'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final guru = filtered[idx];
                          return _GuruPerangkatTile(
                            guru: guru,
                            onTap: () => context.push(
                              RouteConstants.wakilPerangkatDetail.replaceFirst(
                                  ':guruId', '${guru.id}'),
                              extra: guru,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Summary Row ──────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.list});
  final List<GuruPerangkatModel> list;

  @override
  Widget build(BuildContext context) {
    final totalGuru = list.length;
    final lengkap = list.where((g) => g.perangkatBelumLengkap == 0 &&
        g.totalPerangkat > 0).length;
    final belum = totalGuru - lengkap;

    return Row(
      children: <Widget>[
        _Chip(label: 'Total: $totalGuru', color: Colors.blueGrey),
        const SizedBox(width: 8),
        _Chip(label: 'Lengkap: $lengkap', color: Colors.green),
        const SizedBox(width: 8),
        _Chip(label: 'Belum: $belum', color: Colors.orange),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Guru Perangkat Tile ──────────────────────────────────────────────────────
class _GuruPerangkatTile extends StatelessWidget {
  const _GuruPerangkatTile({required this.guru, required this.onTap});
  final GuruPerangkatModel guru;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isComplete =
        guru.totalPerangkat > 0 && guru.perangkatBelumLengkap == 0;
    final statusColor = guru.totalPerangkat == 0
        ? Colors.grey
        : isComplete
            ? Colors.green
            : Colors.orange;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.15),
                    child: Icon(Icons.person_outline, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(guru.namaLengkap,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(guru.mataPelajaran,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      guru.totalPerangkat == 0
                          ? 'Kosong'
                          : isComplete
                              ? 'Lengkap'
                              : 'Belum',
                      style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (guru.totalPerangkat > 0) ...<Widget>[
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: guru.persentaseLengkap,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${guru.perangkatLengkap}/${guru.totalPerangkat}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
