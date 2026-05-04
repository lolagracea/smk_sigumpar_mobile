import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/wakasek_models.dart';
import '../../../providers/wakasek/evaluasi_guru_provider.dart';
import '../../../shared/shell_scaffold.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';

class EvaluasiGuruScreen extends StatefulWidget {
  const EvaluasiGuruScreen({super.key});

  @override
  State<EvaluasiGuruScreen> createState() => _EvaluasiGuruScreenState();
}

class _EvaluasiGuruScreenState extends State<EvaluasiGuruScreen> {
  String _token() => 'dummy-wakasek-token';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EvaluasiGuruProvider>();
      provider.load(token: _token());
      provider.loadGuruList(token: _token());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EvaluasiGuruProvider>();

    return ShellScaffold(
      title: 'Evaluasi Guru',
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => provider.load(token: _token()),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showTambahDialog(context, provider),
        ),
      ],
      body: provider.isLoading
          ? const LoadingWidget()
          : provider.errorMessage != null
          ? ErrorStateWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.load(token: _token()),
      )
          : provider.items.isEmpty
          ? const EmptyStateWidget(
        message: 'Belum ada data evaluasi guru',
      )
          : ListView.separated(
        itemCount: provider.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = provider.items[index];
          return _EvaluasiCard(item: item);
        },
      ),
    );
  }

  void _showTambahDialog(
      BuildContext context, EvaluasiGuruProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: _TambahEvaluasiSheet(token: _token()),
      ),
    );
  }
}

// ─── Card evaluasi ────────────────────────────────────────────

class _EvaluasiCard extends StatelessWidget {
  const _EvaluasiCard({required this.item});

  final EvaluasiGuruModel item;

  @override
  Widget build(BuildContext context) {
    final predikatColor = _predikatColor(item.predikat);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.namaGuru,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (item.mapel != null)
                        Text(
                          item.mapel!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (item.predikat != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: predikatColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: predikatColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      item.predikat!,
                      style: TextStyle(
                        color: predikatColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.skor != null)
              _EvaluasiInfo(label: 'Skor', value: item.skor.toString()),
            if (item.semester != null)
              _EvaluasiInfo(label: 'Semester', value: item.semester!),
            if (item.catatan != null)
              _EvaluasiInfo(label: 'Catatan', value: item.catatan!),
            const SizedBox(height: 4),
            Text(
              'Evaluator: ${item.evaluatorNama} (${item.evaluatorRole})',
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

  Color _predikatColor(String? predikat) {
    switch (predikat?.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _EvaluasiInfo extends StatelessWidget {
  const _EvaluasiInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: <Widget>[
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ─── Tambah Evaluasi Sheet ────────────────────────────────────

class _TambahEvaluasiSheet extends StatefulWidget {
  const _TambahEvaluasiSheet({required this.token});

  final String token;

  @override
  State<_TambahEvaluasiSheet> createState() => _TambahEvaluasiSheetState();
}

class _TambahEvaluasiSheetState extends State<_TambahEvaluasiSheet> {
  GuruMapelModel? _selectedGuru;
  final _mapelController = TextEditingController();
  final _semesterController = TextEditingController();
  final _catatanController = TextEditingController();
  int _skor = 80;
  String _predikat = 'B';

  static const _predikatOptions = <String>['A', 'B', 'C', 'D'];

  @override
  void dispose() {
    _mapelController.dispose();
    _semesterController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  // Hitung predikat otomatis dari skor
  void _updatePredikat(int skor) {
    if (skor >= 90) {
      _predikat = 'A';
    } else if (skor >= 75) {
      _predikat = 'B';
    } else if (skor >= 60) {
      _predikat = 'C';
    } else {
      _predikat = 'D';
    }
  }

  Future<void> _submit() async {
    if (_selectedGuru == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih guru terlebih dahulu')),
      );
      return;
    }

    final provider = context.read<EvaluasiGuruProvider>();

    final success = await provider.create(
      guruId: _selectedGuru!.id,
      namaGuru: _selectedGuru!.nama,
      mapel: _mapelController.text.trim().isEmpty
          ? _selectedGuru!.mapel
          : _mapelController.text.trim(),
      semester: _semesterController.text.trim().isEmpty
          ? null
          : _semesterController.text.trim(),
      skor: _skor,
      predikat: _predikat,
      catatan: _catatanController.text.trim().isEmpty
          ? null
          : _catatanController.text.trim(),
      token: widget.token,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      AppSnackbar.show(
        context,
        message: 'Evaluasi berhasil disimpan',
        isError: false,
      );
    } else {
      AppSnackbar.show(
        context,
        message: provider.errorMessage ?? 'Gagal menyimpan evaluasi',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EvaluasiGuruProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Tambah Evaluasi Guru',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            // Dropdown guru
            provider.isLoadingGuru
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<GuruMapelModel>(
              value: _selectedGuru,
              hint: const Text('Pilih Guru'),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Guru *',
                border: OutlineInputBorder(),
              ),
              items: provider.guruList.map((g) {
                return DropdownMenuItem<GuruMapelModel>(
                  value: g,
                  child: Text(g.nama, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (g) => setState(() => _selectedGuru = g),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _mapelController,
              decoration: const InputDecoration(
                labelText: 'Mata Pelajaran',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _semesterController,
              decoration: const InputDecoration(
                labelText: 'Semester (cth: 2024/2025 Ganjil)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // Slider skor
            Row(
              children: <Widget>[
                const Text('Skor: '),
                Expanded(
                  child: Slider(
                    value: _skor.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: _skor.toString(),
                    onChanged: (v) {
                      setState(() {
                        _skor = v.toInt();
                        _updatePredikat(_skor);
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    _skor.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            // Predikat chips
            Row(
              children: <Widget>[
                const Text('Predikat: '),
                const SizedBox(width: 8),
                ..._predikatOptions.map((p) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ChoiceChip(
                    label: Text(p),
                    selected: _predikat == p,
                    onSelected: (v) {
                      if (v) setState(() => _predikat = p);
                    },
                  ),
                )),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _catatanController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                border: OutlineInputBorder(),
                hintText: 'Tulis catatan evaluasi...',
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: provider.isSaving ? null : _submit,
                icon: provider.isSaving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.save),
                label:
                Text(provider.isSaving ? 'Menyimpan...' : 'Simpan Evaluasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}