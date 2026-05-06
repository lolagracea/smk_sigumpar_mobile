import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wakil_kepsek_provider.dart';

const _aspekOptions = [
  'Pembukaan Pembelajaran',
  'Penguasaan Materi',
  'Metode Mengajar',
  'Pengelolaan Kelas',
  'Penggunaan Media',
  'Interaksi dengan Siswa',
  'Penutup Pembelajaran',
];

Color _getNilaiColor(double? nilai) {
  if (nilai == null) return Colors.grey;
  if (nilai >= 85) return Colors.green;
  if (nilai >= 70) return Colors.orange;
  return Colors.red;
}

String _getNilaiLabel(double? nilai) {
  if (nilai == null) return '—';
  if (nilai >= 85) return 'Sangat Baik';
  if (nilai >= 70) return 'Baik';
  return 'Perlu Perbaikan';
}

class SupervisiScreen extends StatelessWidget {
  const SupervisiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = ctx.read<WakilKepsekProvider>();
        provider.fetchSupervisi();
        provider.fetchGuru();
        return provider;
      },
      child: const _SupervisiView(),
    );
  }
}

class _SupervisiView extends StatefulWidget {
  const _SupervisiView();

  @override
  State<_SupervisiView> createState() => _SupervisiViewState();
}

class _SupervisiViewState extends State<_SupervisiView> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm(BuildContext context, {SupervisiModel? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<WakilKepsekProvider>(),
        child: _SupervisiForm(item: item),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SupervisiModel item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Data Supervisi'),
        content: Text('Hapus supervisi untuk ${item.namaGuru ?? "guru ini"}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = context.read<WakilKepsekProvider>();
              final ok = await provider.deleteSupervisi(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Data supervisi berhasil dihapus' : 'Gagal menghapus'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Supervisi Guru'),
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
          if (provider.isLoadingSupervisi) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)));
          }
          if (provider.errorSupervisi != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(provider.errorSupervisi!),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: provider.fetchSupervisi, child: const Text('Coba Lagi')),
                ],
              ),
            );
          }

          final data = provider.supervisiList;
          final filtered = data.where((d) {
            if (_search.isEmpty) return true;
            final q = _search.toLowerCase();
            return (d.namaGuru ?? '').toLowerCase().contains(q) ||
                (d.kelas ?? '').toLowerCase().contains(q) ||
                (d.mataPelajaran ?? '').toLowerCase().contains(q);
          }).toList();

          // ─── Stats ──────────────────────────────────
          final avgNilai = data.isEmpty
              ? null
              : data.fold(0.0, (sum, d) => sum + (d.nilai ?? 0)) / data.length;

          return Column(
            children: [
              // Stats bar
              Container(
                color: const Color(0xFFEA580C),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _StatChip(label: 'Total Supervisi', value: '${data.length}'),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Rata-rata Nilai',
                      value: avgNilai != null ? avgNilai.toStringAsFixed(1) : '—',
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Guru Disupervisi',
                      value: '${data.map((d) => d.guruId).toSet().length}',
                    ),
                  ],
                ),
              ),

              // Search
              Container(
                color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama guru, kelas, mata pelajaran...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.manage_search, size: 60, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              data.isEmpty ? 'Belum ada data supervisi' : 'Tidak ditemukan',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: provider.fetchSupervisi,
                        color: const Color(0xFFEA580C),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final item = filtered[i];
                            final nilaiColor = _getNilaiColor(item.nilai);
                            final nilaiLabel = _getNilaiLabel(item.nilai);

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
                                        const Icon(Icons.person, color: Color(0xFFEA580C), size: 18),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item.namaGuru ?? 'Guru #${item.guruId}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                        if (item.nilai != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: nilaiColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  item.nilai!.toStringAsFixed(1),
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: nilaiColor, fontSize: 16),
                                                ),
                                                Text(nilaiLabel, style: TextStyle(fontSize: 9, color: nilaiColor)),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(width: 4),
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
                                        const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(item.tanggal, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        if (item.kelas != null && item.kelas!.isNotEmpty) ...[
                                          const SizedBox(width: 12),
                                          const Icon(Icons.class_outlined, size: 13, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(item.kelas!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                        if (item.mataPelajaran != null && item.mataPelajaran!.isNotEmpty) ...[
                                          const SizedBox(width: 12),
                                          const Icon(Icons.menu_book_outlined, size: 13, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(item.mataPelajaran!, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (item.aspekPenilaian != null && item.aspekPenilaian!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '📋 Aspek: ${item.aspekPenilaian}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (item.catatan != null && item.catatan!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '📝 ${item.catatan}',
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Form ─────────────────────────────────────────────────────
class _SupervisiForm extends StatefulWidget {
  final SupervisiModel? item;
  const _SupervisiForm({this.item});

  @override
  State<_SupervisiForm> createState() => _SupervisiFormState();
}

class _SupervisiFormState extends State<_SupervisiForm> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedGuruId;
  String _tanggal = '';
  late final TextEditingController _kelasController;
  late final TextEditingController _mapelController;
  late final TextEditingController _nilaiController;
  late final TextEditingController _catatanController;
  late final TextEditingController _rekomendasiController;
  String _aspekPenilaian = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _selectedGuruId = item?.guruId;
    _tanggal = item?.tanggal ?? DateTime.now().toIso8601String().split('T').first;
    _kelasController = TextEditingController(text: item?.kelas ?? '');
    _mapelController = TextEditingController(text: item?.mataPelajaran ?? '');
    _nilaiController = TextEditingController(text: item?.nilai?.toString() ?? '');
    _catatanController = TextEditingController(text: item?.catatan ?? '');
    _rekomendasiController = TextEditingController(text: item?.rekomendasi ?? '');
    _aspekPenilaian = item?.aspekPenilaian ?? '';
  }

  @override
  void dispose() {
    _kelasController.dispose();
    _mapelController.dispose();
    _nilaiController.dispose();
    _catatanController.dispose();
    _rekomendasiController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _tanggal = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGuruId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guru wajib dipilih!')));
      return;
    }

    setState(() => _loading = true);
    final data = {
      'guru_id': _selectedGuruId,
      'tanggal': _tanggal,
      if (_kelasController.text.trim().isNotEmpty) 'kelas': _kelasController.text.trim(),
      if (_mapelController.text.trim().isNotEmpty) 'mata_pelajaran': _mapelController.text.trim(),
      if (_aspekPenilaian.isNotEmpty) 'aspek_penilaian': _aspekPenilaian,
      if (_nilaiController.text.trim().isNotEmpty) 'nilai': double.tryParse(_nilaiController.text.trim()),
      if (_catatanController.text.trim().isNotEmpty) 'catatan': _catatanController.text.trim(),
      if (_rekomendasiController.text.trim().isNotEmpty) 'rekomendasi': _rekomendasiController.text.trim(),
    };

    final provider = context.read<WakilKepsekProvider>();
    final ok = widget.item != null
        ? await provider.updateSupervisi(widget.item!.id, data)
        : await provider.createSupervisi(data);

    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Data supervisi berhasil disimpan!' : 'Gagal menyimpan data supervisi.'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WakilKepsekProvider>();
    final guruList = provider.guruList;
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
                      isEdit ? 'Edit Supervisi' : 'Tambah Supervisi',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Text('Pencatatan hasil supervisi pembelajaran di kelas', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),

                // Guru
                DropdownButtonFormField<int>(
                  value: _selectedGuruId,
                  decoration: InputDecoration(
                    labelText: 'Guru *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  hint: const Text('Pilih guru'),
                  items: guruList.map((g) {
                    final id = g['id'] as int? ?? g['guru_id'] as int? ?? 0;
                    final nama = g['nama_lengkap'] ?? g['nama'] ?? g['nama_guru'] ?? 'Guru #$id';
                    return DropdownMenuItem(value: id, child: Text('$nama'));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedGuruId = v),
                  validator: (v) => v == null ? 'Guru wajib dipilih' : null,
                ),
                const SizedBox(height: 12),

                // Tanggal
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(_tanggal),
                  ),
                ),
                const SizedBox(height: 12),

                // Kelas & Mapel
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _kelasController,
                        decoration: InputDecoration(labelText: 'Kelas', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _mapelController,
                        decoration: InputDecoration(labelText: 'Mata Pelajaran', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Aspek Penilaian
                DropdownButtonFormField<String>(
                  value: _aspekPenilaian.isEmpty ? null : _aspekPenilaian,
                  decoration: InputDecoration(
                    labelText: 'Aspek Penilaian',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  hint: const Text('Pilih aspek'),
                  items: _aspekOptions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (v) => setState(() => _aspekPenilaian = v ?? ''),
                ),
                const SizedBox(height: 12),

                // Nilai
                TextFormField(
                  controller: _nilaiController,
                  decoration: InputDecoration(
                    labelText: 'Nilai (0-100)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final n = double.tryParse(v);
                    if (n == null || n < 0 || n > 100) return 'Nilai harus 0-100';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Catatan
                TextFormField(
                  controller: _catatanController,
                  decoration: InputDecoration(labelText: 'Catatan', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Rekomendasi
                TextFormField(
                  controller: _rekomendasiController,
                  decoration: InputDecoration(labelText: 'Rekomendasi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  maxLines: 2,
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
                        : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Supervisi'),
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
