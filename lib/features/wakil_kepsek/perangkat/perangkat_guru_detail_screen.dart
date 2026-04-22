import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/wakil_kepsek_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning/wakil_perangkat_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';

class PerangkatGuruDetailScreen extends StatefulWidget {
  const PerangkatGuruDetailScreen({
    required this.guruId,
    this.guruInfo,
    super.key,
  });

  final int guruId;
  final GuruPerangkatModel? guruInfo;

  @override
  State<PerangkatGuruDetailScreen> createState() =>
      _PerangkatGuruDetailScreenState();
}

class _PerangkatGuruDetailScreenState
    extends State<PerangkatGuruDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final token = context.read<AuthProvider>().currentUser?.token ?? '';
    context
        .read<WakilPerangkatProvider>()
        .loadDetailGuru(token, widget.guruId);
  }

  String get _token =>
      context.read<AuthProvider>().currentUser?.token ?? '';

  // ── Dialog Tambah/Edit ────────────────────────────────────────────────────
  Future<void> _showFormDialog({WakilPerangkatModel? existing}) async {
    final namaCtrl =
        TextEditingController(text: existing?.namaPerangkat ?? '');
    final catatanCtrl = TextEditingController(text: existing?.catatan ?? '');
    String jenis = existing?.jenis ?? 'RPP';
    String status = existing?.status ?? 'belum_lengkap';

    final jenisOptions = <String>['RPP', 'Silabus', 'Prota', 'Promes', 'Lainnya'];
    final statusOptions = <String>['belum_lengkap', 'lengkap'];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title:
              Text(existing == null ? 'Tambah Perangkat' : 'Edit Perangkat'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Perangkat *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: jenis,
                  decoration: const InputDecoration(
                    labelText: 'Jenis',
                    border: OutlineInputBorder(),
                  ),
                  items: jenisOptions
                      .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                      .toList(),
                  onChanged: (v) => setDState(() => jenis = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: statusOptions
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s == 'lengkap'
                                ? 'Lengkap'
                                : 'Belum Lengkap'),
                          ))
                      .toList(),
                  onChanged: (v) => setDState(() => status = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: catatanCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            Consumer<WakilPerangkatProvider>(
              builder: (_, prov, __) => FilledButton(
                onPressed: prov.isSaving
                    ? null
                    : () async {
                        if (namaCtrl.text.trim().isEmpty) return;
                        bool ok;
                        if (existing == null) {
                          ok = await prov.createPerangkat(
                            _token,
                            widget.guruId,
                            namaCtrl.text.trim(),
                            jenis,
                            status,
                            catatan: catatanCtrl.text.trim(),
                          );
                        } else {
                          ok = await prov.updatePerangkat(
                            _token,
                            existing.id,
                            namaCtrl.text.trim(),
                            jenis,
                            status,
                            catatan: catatanCtrl.text.trim(),
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(prov.saveError ?? 'Gagal')),
                          );
                        }
                      },
                child: prov.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(WakilPerangkatModel perangkat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Perangkat?'),
        content: Text(
            'Apakah kamu yakin ingin menghapus "${perangkat.namaPerangkat}"?'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await context
          .read<WakilPerangkatProvider>()
          .deletePerangkat(_token, perangkat.id);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<WakilPerangkatProvider>().saveError ??
                'Gagal menghapus'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WakilPerangkatProvider>();
    final detail = prov.detail;
    final guruNama = detail?.guru.namaLengkap ??
        widget.guruInfo?.namaLengkap ??
        'Detail Guru';

    return ShellScaffold(
      title: guruNama,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Tambah Perangkat',
          onPressed: prov.isLoadingDetail ? null : () => _showFormDialog(),
        ),
      ],
      body: prov.isLoadingDetail
          ? const LoadingWidget()
          : prov.errorDetail != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(prov.errorDetail!),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              : detail == null
                  ? const Center(child: Text('Tidak ada data'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // ── Info Guru ───────────────────────────────────
                        _GuruInfoCard(guru: detail.guru),
                        const SizedBox(height: 12),

                        // ── Header Daftar ───────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Daftar Perangkat (${detail.perangkatList.length})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            TextButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // ── Daftar Perangkat ────────────────────────────
                        Expanded(
                          child: detail.perangkatList.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Belum ada perangkat.\nTambahkan dengan tombol + di atas.',
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: detail.perangkatList.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (ctx, idx) {
                                    final p = detail.perangkatList[idx];
                                    return _PerangkatTile(
                                      perangkat: p,
                                      onEdit: () =>
                                          _showFormDialog(existing: p),
                                      onDelete: () => _confirmDelete(p),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
    );
  }
}

// ─── Widget: Guru Info Card ───────────────────────────────────────────────────
class _GuruInfoCard extends StatelessWidget {
  const _GuruInfoCard({required this.guru});
  final GuruInfoModel guru;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.person,
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(guru.namaLengkap,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('NIP: ${guru.nip}',
                      style: const TextStyle(fontSize: 12)),
                  Text(guru.mataPelajaran,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget: Perangkat Tile ───────────────────────────────────────────────────
class _PerangkatTile extends StatelessWidget {
  const _PerangkatTile({
    required this.perangkat,
    required this.onEdit,
    required this.onDelete,
  });

  final WakilPerangkatModel perangkat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = perangkat.isLengkap ? Colors.green : Colors.orange;

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.description_outlined, color: color),
        ),
        title: Text(perangkat.namaPerangkat,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Jenis: ${perangkat.jenis}'),
            if (perangkat.catatan != null && perangkat.catatan!.isNotEmpty)
              Text(perangkat.catatan!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        isThreeLine: perangkat.catatan != null && perangkat.catatan!.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                perangkat.isLengkap ? 'Lengkap' : 'Belum',
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.red),
                onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
