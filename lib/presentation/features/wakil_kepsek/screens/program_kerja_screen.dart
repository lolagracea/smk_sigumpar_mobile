import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wakil_kepsek_provider.dart';

// ─── Status Config ────────────────────────────────────────────
const _statusConfig = {
  'belum_mulai': {'label': 'Belum Mulai', 'icon': '⏳', 'color': Colors.grey},
  'sedang_berjalan': {'label': 'Sedang Berjalan', 'icon': '🔄', 'color': Colors.blue},
  'selesai': {'label': 'Selesai', 'icon': '✅', 'color': Colors.green},
  'ditunda': {'label': 'Ditunda', 'icon': '⚠️', 'color': Colors.orange},
};

const _bidangOptions = ['Kurikulum', 'Kesiswaan', 'Sarana & Prasarana', 'Humas', 'Lainnya'];

class ProgramKerjaScreen extends StatelessWidget {
  const ProgramKerjaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = ctx.read<WakilKepsekProvider>();
        provider.fetchProgramKerja();
        return provider;
      },
      child: const _ProgramKerjaView(),
    );
  }
}

class _ProgramKerjaView extends StatefulWidget {
  const _ProgramKerjaView();

  @override
  State<_ProgramKerjaView> createState() => _ProgramKerjaViewState();
}

class _ProgramKerjaViewState extends State<_ProgramKerjaView> {
  String _filterStatus = '';
  String _filterBidang = '';

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  Color _getBidangColor(String bidang) {
    switch (bidang) {
      case 'Kurikulum':
        return Colors.blue;
      case 'Kesiswaan':
        return Colors.purple;
      case 'Sarana & Prasarana':
        return Colors.green;
      case 'Humas':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  void _openForm(BuildContext context, {ProgramKerjaModel? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<WakilKepsekProvider>(),
        child: _ProgramKerjaForm(item: item),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProgramKerjaModel item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Program Kerja'),
        content: Text('Hapus "${item.namaProgram}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = context.read<WakilKepsekProvider>();
              final ok = await provider.deleteProgramKerja(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Program kerja berhasil dihapus' : 'Gagal menghapus program kerja'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Program Kerja'),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: Consumer<WakilKepsekProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingProgramKerja) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)));
          }

          if (provider.errorProgramKerja != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(provider.errorProgramKerja!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: provider.fetchProgramKerja,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          // ─── Filter stats ──────────────────────────────
          final data = provider.programKerjaList;

          final filtered = data.where((d) {
            if (_filterStatus.isNotEmpty && d.status != _filterStatus) return false;
            if (_filterBidang.isNotEmpty && d.bidang != _filterBidang) return false;
            return true;
          }).toList();

          return Column(
            children: [
              // ─── Stats ────────────────────────────────
              Container(
                color: const Color(0xFFEA580C),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: _statusConfig.entries.map((entry) {
                    final count = data.where((d) => d.status == entry.key).length;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text('$count', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(
                              entry.value['label'] as String,
                              style: const TextStyle(color: Colors.white70, fontSize: 9),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList()
                    ..last,
                ),
              ),

              // ─── Filter ───────────────────────────────
              Container(
                color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus.isEmpty ? null : _filterStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Semua Status')),
                          ..._statusConfig.entries.map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value['label'] as String),
                              )),
                        ],
                        onChanged: (v) => setState(() => _filterStatus = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterBidang.isEmpty ? null : _filterBidang,
                        decoration: InputDecoration(
                          labelText: 'Bidang',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Semua Bidang')),
                          ..._bidangOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                        ],
                        onChanged: (v) => setState(() => _filterBidang = v ?? ''),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── List ─────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.work_outline, size: 60, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              data.isEmpty ? 'Belum ada program kerja' : 'Tidak ada yang sesuai filter',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if (data.isEmpty) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _openForm(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah Program'),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
                              ),
                            ]
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: provider.fetchProgramKerja,
                        color: const Color(0xFFEA580C),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final item = filtered[i];
                            final cfg = _statusConfig[item.status] ?? _statusConfig['belum_mulai']!;
                            final statusColor = cfg['color'] as Color;
                            final bidangColor = _getBidangColor(item.bidang);

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.namaProgram,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (val) {
                                            if (val == 'edit') _openForm(context, item: item);
                                            if (val == 'delete') _confirmDelete(context, item);
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                                          ],
                                          child: const Icon(Icons.more_vert, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: bidangColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.bidang,
                                            style: TextStyle(fontSize: 11, color: bidangColor, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${cfg['icon']} ${cfg['label']}',
                                            style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_formatDate(item.tanggalMulai)} — ${_formatDate(item.tanggalSelesai)}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    if (item.penanggungJawab != null && item.penanggungJawab!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(item.penanggungJawab!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                    if (item.deskripsi != null && item.deskripsi!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        item.deskripsi!,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        backgroundColor: const Color(0xFFEA580C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── Form Bottom Sheet ────────────────────────────────────────
class _ProgramKerjaForm extends StatefulWidget {
  final ProgramKerjaModel? item;
  const _ProgramKerjaForm({this.item});

  @override
  State<_ProgramKerjaForm> createState() => _ProgramKerjaFormState();
}

class _ProgramKerjaFormState extends State<_ProgramKerjaForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _penanggungJawabController;
  late final TextEditingController _deskripsiController;

  String _bidang = 'Kurikulum';
  String _status = 'belum_mulai';
  String _tanggalMulai = '';
  String _tanggalSelesai = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _namaController = TextEditingController(text: item?.namaProgram ?? '');
    _penanggungJawabController = TextEditingController(text: item?.penanggungJawab ?? '');
    _deskripsiController = TextEditingController(text: item?.deskripsi ?? '');
    _bidang = item?.bidang ?? 'Kurikulum';
    _status = item?.status ?? 'belum_mulai';
    _tanggalMulai = item?.tanggalMulai ?? '';
    _tanggalSelesai = item?.tanggalSelesai ?? '';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _penanggungJawabController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isMulai) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final str = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isMulai) _tanggalMulai = str;
        else _tanggalSelesai = str;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggalMulai.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tanggal mulai wajib diisi!')));
      return;
    }

    setState(() => _loading = true);
    final data = {
      'nama_program': _namaController.text.trim(),
      'bidang': _bidang,
      'tanggal_mulai': _tanggalMulai,
      if (_tanggalSelesai.isNotEmpty) 'tanggal_selesai': _tanggalSelesai,
      if (_penanggungJawabController.text.trim().isNotEmpty) 'penanggung_jawab': _penanggungJawabController.text.trim(),
      'status': _status,
      if (_deskripsiController.text.trim().isNotEmpty) 'deskripsi': _deskripsiController.text.trim(),
    };

    final provider = context.read<WakilKepsekProvider>();
    final ok = widget.item != null
        ? await provider.updateProgramKerja(widget.item!.id, data)
        : await provider.createProgramKerja(data);

    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Program kerja berhasil disimpan!' : 'Gagal menyimpan program kerja.'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Program Kerja' : 'Tambah Program Kerja',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Text('Program Kerja Wakil Kepala Sekolah', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),

                // Nama Program
                TextFormField(
                  controller: _namaController,
                  decoration: InputDecoration(
                    labelText: 'Nama Program *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama program wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                // Bidang
                DropdownButtonFormField<String>(
                  value: _bidang,
                  decoration: InputDecoration(
                    labelText: 'Bidang',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _bidangOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) => setState(() => _bidang = v ?? 'Kurikulum'),
                ),
                const SizedBox(height: 12),

                // Tanggal Mulai & Selesai
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tanggal Mulai *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(_tanggalMulai.isEmpty ? 'Pilih tanggal' : _tanggalMulai, style: TextStyle(color: _tanggalMulai.isEmpty ? Colors.grey : null)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tanggal Selesai',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(_tanggalSelesai.isEmpty ? 'Opsional' : _tanggalSelesai, style: TextStyle(color: _tanggalSelesai.isEmpty ? Colors.grey : null)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Penanggung Jawab
                TextFormField(
                  controller: _penanggungJawabController,
                  decoration: InputDecoration(
                    labelText: 'Penanggung Jawab',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Status
                const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _statusConfig.entries.map((e) {
                    final isSelected = _status == e.key;
                    final color = e.value['color'] as Color;
                    return ChoiceChip(
                      label: Text('${e.value['icon']} ${e.value['label']}'),
                      selected: isSelected,
                      selectedColor: color.withOpacity(0.2),
                      onSelected: (_) => setState(() => _status = e.key),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Deskripsi
                TextFormField(
                  controller: _deskripsiController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Program'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
