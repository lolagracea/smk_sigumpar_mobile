import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/wakasek_models.dart';
import '../../../providers/wakasek/catatan_mengajar_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';

class CatatanMengajarScreen extends StatefulWidget {
  const CatatanMengajarScreen({super.key});

  @override
  State<CatatanMengajarScreen> createState() => _CatatanMengajarScreenState();
}

class _CatatanMengajarScreenState extends State<CatatanMengajarScreen> {
  String _token() => 'dummy-wakasek-token';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<CatatanMengajarProvider>().load(token: _token());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatatanMengajarProvider>();

    return ShellScaffold(
      title: 'Catatan Mengajar',
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterSheet(context, provider),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _load,
        ),
      ],
      body: Column(
        children: <Widget>[
          // ─── Filter badge aktif ───────────────────────────
          if (provider.filterTanggal != null || provider.filterGuruId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  if (provider.filterTanggal != null)
                    Chip(
                      label: Text('Tgl: ${provider.filterTanggal!}',
                          style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        provider.setFilter(tanggal: null);
                        _load();
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),

          // ─── Content ───────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget()
                : provider.errorMessage != null
                ? ErrorStateWidget(
              message: provider.errorMessage!,
              onRetry: _load,
            )
                : provider.items.isEmpty
                ? const EmptyStateWidget(
              message: 'Belum ada catatan mengajar',
            )
                : ListView.separated(
              itemCount: provider.items.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _CatatanCard(
                    item: provider.items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet(
      BuildContext context, CatatanMengajarProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _FilterSheet(
        currentTanggal: provider.filterTanggal,
        onApply: (tanggal) {
          provider.setFilter(tanggal: tanggal);
          _load();
          Navigator.pop(ctx);
        },
        onReset: () {
          provider.resetFilter();
          _load();
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─── Catatan card ────────────────────────────────────────────

class _CatatanCard extends StatefulWidget {
  const _CatatanCard({required this.item});

  final CatatanMengajarModel item;

  @override
  State<_CatatanCard> createState() => _CatatanCardState();
}

class _CatatanCardState extends State<_CatatanCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: Text(
              item.namaGuru,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${item.mataPelajaran ?? 'Mata Pelajaran tidak dicatat'}'
                  '\n${item.tanggal}'
                  '${item.jamMulai != null ? ' • ${item.jamMulai} - ${item.jamSelesai ?? '...'}' : ''}',
              maxLines: 2,
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Divider(height: 8),
                  _DetailRow(label: 'Materi', value: item.materi),
                  if (item.metode != null)
                    _DetailRow(label: 'Metode', value: item.metode!),
                  if (item.kendala != null && item.kendala!.isNotEmpty)
                    _DetailRow(label: 'Kendala', value: item.kendala!),
                  if (item.tindakLanjut != null &&
                      item.tindakLanjut!.isNotEmpty)
                    _DetailRow(
                        label: 'Tindak Lanjut', value: item.tindakLanjut!),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ─── Filter sheet ─────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.currentTanggal,
    required this.onApply,
    required this.onReset,
  });

  final String? currentTanggal;
  final void Function(String? tanggal) onApply;
  final VoidCallback onReset;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.currentTanggal != null) {
      _selectedDate = DateTime.tryParse(widget.currentTanggal!);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Filter Catatan Mengajar',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Text('Tanggal', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _selectedDate != null
                  ? _formatDate(_selectedDate!)
                  : 'Pilih Tanggal',
            ),
          ),
          if (_selectedDate != null)
            TextButton(
              onPressed: () => setState(() => _selectedDate = null),
              child: const Text('Hapus filter tanggal'),
            ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onReset,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => widget.onApply(
                    _selectedDate != null ? _formatDate(_selectedDate!) : null,
                  ),
                  child: const Text('Terapkan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}