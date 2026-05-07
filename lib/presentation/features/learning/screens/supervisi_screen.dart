import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';

const _aspekOptions = [
  'Pembukaan Pembelajaran', 'Penguasaan Materi', 'Metode Mengajar',
  'Pengelolaan Kelas', 'Penggunaan Media', 'Interaksi dengan Siswa',
  'Penutup Pembelajaran',
];

Color _nilaiColor(double? n) {
  if (n == null) return Colors.grey;
  if (n >= 85) return Colors.green;
  if (n >= 70) return Colors.orange;
  return Colors.red;
}

String _nilaiLabel(double? n) {
  if (n == null) return '—';
  if (n >= 85) return 'Sangat Baik';
  if (n >= 70) return 'Baik';
  return 'Perlu Perbaikan';
}

class _Supervisi {
  final int id;
  final int guruId;
  final String? namaGuru;
  final String tanggal;
  final String? kelas;
  final String? mataPelajaran;
  final String? aspekPenilaian;
  final double? nilai;
  final String? catatan;
  final String? rekomendasi;

  const _Supervisi({required this.id, required this.guruId, this.namaGuru, required this.tanggal, this.kelas, this.mataPelajaran, this.aspekPenilaian, this.nilai, this.catatan, this.rekomendasi});

  factory _Supervisi.fromJson(Map<String, dynamic> j) => _Supervisi(
    id: j['id'] ?? 0,
    guruId: j['guru_id'] ?? 0,
    namaGuru: j['nama_guru'],
    tanggal: (j['tanggal'] ?? '').toString().split('T').first,
    kelas: j['kelas'],
    mataPelajaran: j['mata_pelajaran'],
    aspekPenilaian: j['aspek_penilaian'],
    nilai: j['nilai'] != null ? double.tryParse(j['nilai'].toString()) : null,
    catatan: j['catatan'],
    rekomendasi: j['rekomendasi'],
  );
}

class SupervisiScreen extends StatefulWidget {
  const SupervisiScreen({super.key});
  @override
  State<SupervisiScreen> createState() => _SupervisiScreenState();
}

class _SupervisiScreenState extends State<SupervisiScreen> {
  late final DioClient _dio;
  List<_Supervisi> _list = [];
  List<Map<String, dynamic>> _guruList = [];
  bool _loading = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _dio = sl<DioClient>();
    _load();
    _loadGuru();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.get(ApiEndpoints.wakilSupervisi);
      final raw = res.data;
      final rows = raw is List ? raw : (raw is Map ? raw['data'] ?? [] : []);
      setState(() => _list = (rows as List).map((e) => _Supervisi.fromJson(Map<String, dynamic>.from(e))).toList());
    } catch (_) {
      setState(() => _error = 'Gagal memuat data supervisi');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadGuru() async {
    try {
      final res = await _dio.get(ApiEndpoints.teachers);
      final raw = res.data;
      final rows = raw is List ? raw : (raw is Map ? raw['data'] ?? [] : []);
      setState(() => _guruList = (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (_) {}
  }

  Future<void> _delete(_Supervisi item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data Supervisi'),
        content: Text('Hapus supervisi untuk ${item.namaGuru ?? "guru ini"}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _dio.delete('${ApiEndpoints.wakilSupervisi}/${item.id}');
      _showSnack('Data supervisi berhasil dihapus', Colors.green);
      _load();
    } catch (_) {
      _showSnack('Gagal menghapus', Colors.red);
    }
  }

  void _openForm({_Supervisi? item}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => _SupervisiForm(item: item, dio: _dio, guruList: _guruList, onSaved: _load),
    );
  }

  void _showSnack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _list.where((d) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return (d.namaGuru ?? '').toLowerCase().contains(q) || (d.kelas ?? '').toLowerCase().contains(q) || (d.mataPelajaran ?? '').toLowerCase().contains(q);
    }).toList();
    final avgNilai = _list.isEmpty ? null : _list.fold(0.0, (sum, d) => sum + (d.nilai ?? 0)) / _list.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Supervisi Guru', style: TextStyle(fontSize: 16)),
          Text('Penilaian pembelajaran di kelas', style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openForm()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8), Text(_error!), const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
                ]))
              : Column(children: [
                  Container(
                    color: const Color(0xFFEA580C),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(children: [
                      _StatChip(label: 'Total Supervisi', value: '${_list.length}'),
                      const SizedBox(width: 8),
                      _StatChip(label: 'Rata-rata Nilai', value: avgNilai != null ? avgNilai.toStringAsFixed(1) : '—'),
                      const SizedBox(width: 8),
                      _StatChip(label: 'Guru Disupervisi', value: '${_list.map((d) => d.guruId).toSet().length}'),
                    ]),
                  ),
                  Container(
                    color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: InputDecoration(hintText: 'Cari nama guru, kelas, mata pelajaran...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  Expanded(child: filtered.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.manage_search, size: 60, color: Colors.grey), const SizedBox(height: 12), Text(_list.isEmpty ? 'Belum ada data supervisi' : 'Tidak ditemukan', style: const TextStyle(color: Colors.grey))]))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(0xFFEA580C),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              final nc = _nilaiColor(item.nilai);
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      const Icon(Icons.person, color: Color(0xFFEA580C), size: 18),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(item.namaGuru ?? 'Guru #${item.guruId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                      if (item.nilai != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: nc.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                          child: Column(children: [
                                            Text(item.nilai!.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: nc, fontSize: 16)),
                                            Text(_nilaiLabel(item.nilai), style: TextStyle(fontSize: 9, color: nc)),
                                          ]),
                                        ),
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        onSelected: (val) { if (val == 'edit') _openForm(item: item); if (val == 'delete') _delete(item); },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                                        ],
                                        child: const Icon(Icons.more_vert, color: Colors.grey),
                                      ),
                                    ]),
                                    const SizedBox(height: 8),
                                    Wrap(spacing: 8, children: [
                                      Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.calendar_today, size: 13, color: Colors.grey), const SizedBox(width: 4), Text(item.tanggal, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
                                      if (item.kelas?.isNotEmpty == true) Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.class_outlined, size: 13, color: Colors.grey), const SizedBox(width: 4), Text(item.kelas!, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
                                      if (item.mataPelajaran?.isNotEmpty == true) Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.menu_book_outlined, size: 13, color: Colors.grey), const SizedBox(width: 4), Text(item.mataPelajaran!, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
                                    ]),
                                    if (item.catatan?.isNotEmpty == true) ...[const SizedBox(height: 4), Text('📝 ${item.catatan}', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis)],
                                  ]),
                                ),
                              );
                            },
                          ),
                        )),
                ]),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), backgroundColor: const Color(0xFFEA580C), child: const Icon(Icons.add, color: Colors.white)),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label; final String value;
  const _StatChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
    ]),
  ));
}

class _SupervisiForm extends StatefulWidget {
  final _Supervisi? item;
  final DioClient dio;
  final List<Map<String, dynamic>> guruList;
  final VoidCallback onSaved;
  const _SupervisiForm({this.item, required this.dio, required this.guruList, required this.onSaved});
  @override
  State<_SupervisiForm> createState() => _SupervisiFormState();
}

class _SupervisiFormState extends State<_SupervisiForm> {
  final _formKey = GlobalKey<FormState>();
  int? _guruId;
  String _tanggal = '';
  late final TextEditingController _kelasCtrl, _mapelCtrl, _nilaiCtrl, _catatanCtrl, _rekCtrl;
  String _aspek = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _guruId = it?.guruId;
    _tanggal = it?.tanggal ?? DateTime.now().toIso8601String().split('T').first;
    _kelasCtrl = TextEditingController(text: it?.kelas ?? '');
    _mapelCtrl = TextEditingController(text: it?.mataPelajaran ?? '');
    _nilaiCtrl = TextEditingController(text: it?.nilai?.toString() ?? '');
    _catatanCtrl = TextEditingController(text: it?.catatan ?? '');
    _rekCtrl = TextEditingController(text: it?.rekomendasi ?? '');
    _aspek = it?.aspekPenilaian ?? '';
  }

  @override
  void dispose() {
    for (final c in [_kelasCtrl, _mapelCtrl, _nilaiCtrl, _catatanCtrl, _rekCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (p != null) setState(() => _tanggal = '${p.year}-${p.month.toString().padLeft(2,'0')}-${p.day.toString().padLeft(2,'0')}');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _guruId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guru wajib dipilih!')));
      return;
    }
    setState(() => _loading = true);
    final data = {
      'guru_id': _guruId,
      'tanggal': _tanggal,
      if (_kelasCtrl.text.trim().isNotEmpty) 'kelas': _kelasCtrl.text.trim(),
      if (_mapelCtrl.text.trim().isNotEmpty) 'mata_pelajaran': _mapelCtrl.text.trim(),
      if (_aspek.isNotEmpty) 'aspek_penilaian': _aspek,
      if (_nilaiCtrl.text.trim().isNotEmpty) 'nilai': double.tryParse(_nilaiCtrl.text.trim()),
      if (_catatanCtrl.text.trim().isNotEmpty) 'catatan': _catatanCtrl.text.trim(),
      if (_rekCtrl.text.trim().isNotEmpty) 'rekomendasi': _rekCtrl.text.trim(),
    };
    try {
      if (widget.item != null) await widget.dio.put('${ApiEndpoints.wakilSupervisi}/${widget.item!.id}', data: data);
      else await widget.dio.post(ApiEndpoints.wakilSupervisi, data: data);
      widget.onSaved();
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil disimpan!'), backgroundColor: Colors.green)); }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.item != null ? 'Edit Supervisi' : 'Tambah Supervisi', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _guruId,
          decoration: InputDecoration(labelText: 'Guru *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          hint: const Text('Pilih guru'),
          items: widget.guruList.map((g) {
            final id = g['id'] as int? ?? g['guru_id'] as int? ?? 0;
            final nama = g['nama_lengkap'] ?? g['nama'] ?? 'Guru #$id';
            return DropdownMenuItem(value: id, child: Text('$nama'));
          }).toList(),
          onChanged: (v) => setState(() => _guruId = v),
          validator: (v) => v == null ? 'Guru wajib dipilih' : null,
        ),
        const SizedBox(height: 12),
        InkWell(onTap: _pickDate, child: InputDecorator(decoration: InputDecoration(labelText: 'Tanggal', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), suffixIcon: const Icon(Icons.calendar_today)), child: Text(_tanggal))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: _kelasCtrl, decoration: InputDecoration(labelText: 'Kelas', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _mapelCtrl, decoration: InputDecoration(labelText: 'Mata Pelajaran', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _aspek.isEmpty ? null : _aspek,
          decoration: InputDecoration(labelText: 'Aspek Penilaian', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          hint: const Text('Pilih aspek'),
          items: _aspekOptions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
          onChanged: (v) => setState(() => _aspek = v ?? ''),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _nilaiCtrl, decoration: InputDecoration(labelText: 'Nilai (0-100)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), keyboardType: TextInputType.number, validator: (v) { if (v == null || v.isEmpty) return null; final n = double.tryParse(v); if (n == null || n < 0 || n > 100) return 'Nilai harus 0-100'; return null; }),
        const SizedBox(height: 12),
        TextFormField(controller: _catatanCtrl, decoration: InputDecoration(labelText: 'Catatan', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), maxLines: 3),
        const SizedBox(height: 12),
        TextFormField(controller: _rekCtrl, decoration: InputDecoration(labelText: 'Rekomendasi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), maxLines: 2),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.item != null ? 'Simpan Perubahan' : 'Tambah Supervisi'),
        )),
      ]))),
    );
  }
}
