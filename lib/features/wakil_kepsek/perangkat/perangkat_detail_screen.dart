import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/wakasek_models.dart';
import '../../../providers/wakasek/perangkat_provider.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/loading_widget.dart';

class PerangkatDetailScreen extends StatefulWidget {
  const PerangkatDetailScreen({required this.perangkat, super.key});

  final PerangkatModel perangkat;

  @override
  State<PerangkatDetailScreen> createState() => _PerangkatDetailScreenState();
}

class _PerangkatDetailScreenState extends State<PerangkatDetailScreen> {
  String _token() => 'dummy-wakasek-token'; // ganti saat Keycloak aktif

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<PerangkatProvider>()
          .loadRiwayat(id: widget.perangkat.id, token: _token());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerangkatProvider>();

    // Cari item yang mungkin sudah di-update oleh review
    final perangkat = provider.items.firstWhere(
          (p) => p.id == widget.perangkat.id,
      orElse: () => widget.perangkat,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Perangkat'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ─── Info dokumen ────────────────────────────────
              _SectionCard(
                title: 'Informasi Dokumen',
                child: Column(
                  children: <Widget>[
                    _InfoRow(label: 'Nama Dokumen', value: perangkat.namaDokumen),
                    _InfoRow(label: 'Jenis', value: perangkat.jenisDokumen),
                    _InfoRow(label: 'Nama Guru', value: perangkat.namaGuru),
                    _InfoRow(label: 'File', value: perangkat.fileName),
                    _InfoRow(
                        label: 'Tanggal Upload', value: perangkat.tanggalUpload),
                    _InfoRow(
                        label: 'Versi',
                        value: (perangkat.versi ?? 1).toString()),
                    _InfoRow(
                      label: 'Status Review',
                      value: perangkat.statusReview,
                      valueColor: _statusColor(perangkat.statusReview),
                    ),
                    if (perangkat.catatanReview != null)
                      _InfoRow(
                          label: 'Catatan Review',
                          value: perangkat.catatanReview!),
                    if (perangkat.reviewedBy != null)
                      _InfoRow(
                          label: 'Direview oleh', value: perangkat.reviewedBy!),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Tombol review ───────────────────────────────
              if (perangkat.statusReview == 'menunggu' ||
                  perangkat.statusReview == 'revisi')
                _SectionCard(
                  title: 'Beri Review',
                  child: _ReviewForm(
                    perangkat: perangkat,
                    token: _token(),
                  ),
                ),

              if (perangkat.statusReview == 'disetujui' ||
                  perangkat.statusReview == 'ditolak')
                Card(
                  color: perangkat.statusReview == 'disetujui'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          perangkat.statusReview == 'disetujui'
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color: perangkat.statusReview == 'disetujui'
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            perangkat.statusReview == 'disetujui'
                                ? 'Perangkat ini sudah disetujui'
                                : 'Perangkat ini sudah ditolak',
                            style: TextStyle(
                              color: perangkat.statusReview == 'disetujui'
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ─── Riwayat review ──────────────────────────────
              _SectionCard(
                title: 'Riwayat Review',
                child: provider.isLoadingRiwayat
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LoadingWidget(),
                )
                    : provider.riwayat.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Belum ada riwayat review',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
                    : Column(
                  children: provider.riwayat
                      .map((r) => _RiwayatTile(riwayat: r))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'disetujui':
        return Colors.green;
      case 'revisi':
        return Colors.orange;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ─── Review Form ──────────────────────────────────────────────

class _ReviewForm extends StatefulWidget {
  const _ReviewForm({required this.perangkat, required this.token});

  final PerangkatModel perangkat;
  final String token;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  String _selectedStatus = 'disetujui';
  final _catatanController = TextEditingController();

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<PerangkatProvider>();

    final success = await provider.review(
      id: widget.perangkat.id,
      status: _selectedStatus,
      catatan: _catatanController.text.trim().isEmpty
          ? null
          : _catatanController.text.trim(),
      token: widget.token,
    );

    if (!mounted) return;

    if (success) {
      AppSnackbar.show(
        context,
        message: 'Review berhasil disimpan',
        isError: false,
      );
      // Reload riwayat setelah review
      await provider.loadRiwayat(
          id: widget.perangkat.id, token: widget.token);
    } else {
      AppSnackbar.show(
        context,
        message: provider.errorMessage ?? 'Gagal menyimpan review',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerangkatProvider>();
    const statuses = <String>['disetujui', 'revisi', 'ditolak'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Keputusan', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: statuses.map((s) {
            Color color;
            switch (s) {
              case 'disetujui':
                color = Colors.green;
                break;
              case 'revisi':
                color = Colors.orange;
                break;
              default:
                color = Colors.red;
            }

            return ChoiceChip(
              label: Text(s),
              selected: _selectedStatus == s,
              selectedColor: color.withOpacity(0.2),
              onSelected: (v) {
                if (v) setState(() => _selectedStatus = s);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _catatanController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Catatan (opsional)',
            border: OutlineInputBorder(),
            hintText: 'Tulis catatan review...',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: provider.isReviewing ? null : _submit,
            icon: provider.isReviewing
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.send),
            label: Text(
                provider.isReviewing ? 'Menyimpan...' : 'Kirim Review'),
          ),
        ),
      ],
    );
  }
}

// ─── Riwayat tile ─────────────────────────────────────────────

class _RiwayatTile extends StatelessWidget {
  const _RiwayatTile({required this.riwayat});

  final RiwayatReviewModel riwayat;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (riwayat.status) {
      case 'disetujui':
        statusColor = Colors.green;
        break;
      case 'revisi':
        statusColor = Colors.orange;
        break;
      case 'ditolak':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    riwayat.reviewerNama,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    riwayat.status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              riwayat.reviewerRole,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            if (riwayat.komentar != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(riwayat.komentar!),
            ],
            const SizedBox(height: 4),
            Text(
              riwayat.createdAt,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
