import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/models/wakasek_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wakasek/perangkat_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import 'perangkat_detail_screen.dart';

class PerangkatScreen extends StatefulWidget {
  const PerangkatScreen({super.key});

  @override
  State<PerangkatScreen> createState() => _PerangkatScreenState();
}

class _PerangkatScreenState extends State<PerangkatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _token() => 'dummy-wakasek-token'; // ganti saat Keycloak aktif

  Future<void> _load() async {
    final provider = context.read<PerangkatProvider>();
    await provider.load(token: _token());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerangkatProvider>();

    return ShellScaffold(
      title: 'Perangkat Pembelajaran',
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
          // ─── Filter chips aktif ───────────────────────────
          if (provider.filterStatus != null || provider.filterJenis != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  if (provider.filterStatus != null)
                    _FilterChip(
                      label: provider.filterStatus!,
                      onDeleted: () {
                        provider.setFilter(status: null);
                        _load();
                      },
                    ),
                  if (provider.filterJenis != null)
                    _FilterChip(
                      label: provider.filterJenis!,
                      onDeleted: () {
                        provider.setFilter(jenis: null);
                        _load();
                      },
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
              message: 'Belum ada perangkat pembelajaran',
            )
                : ListView.separated(
              itemCount: provider.items.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return _PerangkatCard(
                  item: item,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: PerangkatDetailScreen(
                          perangkat: item,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet(
      BuildContext context, PerangkatProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _FilterSheet(
        currentStatus: provider.filterStatus,
        onApply: (status, jenis) {
          provider.setFilter(status: status, jenis: jenis);
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

// ─── Card item ────────────────────────────────────────────────

class _PerangkatCard extends StatelessWidget {
  const _PerangkatCard({required this.item, required this.onTap});

  final PerangkatModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.description_outlined,
          color: _statusColor(context, item.statusReview),
        ),
        title: Text(
          item.namaDokumen,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.namaGuru} • ${item.jenisDokumen}\n${item.tanggalUpload}',
          maxLines: 2,
        ),
        isThreeLine: true,
        trailing: _StatusBadge(status: item.statusReview),
        onTap: onTap,
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'disetujui':
        color = Colors.green;
        break;
      case 'revisi':
        color = Colors.orange;
        break;
      case 'ditolak':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDeleted,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ─── Filter bottom sheet ──────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.currentStatus,
    required this.onApply,
    required this.onReset,
  });

  final String? currentStatus;
  final void Function(String? status, String? jenis) onApply;
  final VoidCallback onReset;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    const statuses = <String>['menunggu', 'disetujui', 'revisi', 'ditolak'];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Filter', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Text('Status Review',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: statuses.map((s) {
              return ChoiceChip(
                label: Text(s),
                selected: _status == s,
                onSelected: (v) => setState(() => _status = v ? s : null),
              );
            }).toList(),
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
                  onPressed: () => widget.onApply(_status, null),
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