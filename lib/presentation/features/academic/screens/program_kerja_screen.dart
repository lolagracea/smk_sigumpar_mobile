import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';

// ─── Model ───────────────────────────────────────────────────────────────────
class _ProgramKerja {
  final int id;
  final String namaProgram;
  final String bidang;
  final String tanggalMulai;
  final String? tanggalSelesai;
  final String? penanggungJawab;
  final String status;
  final String? deskripsi;

  const _ProgramKerja({
    required this.id,
    required this.namaProgram,
    required this.bidang,
    required this.tanggalMulai,
    this.tanggalSelesai,
    this.penanggungJawab,
    required this.status,
    this.deskripsi,
  });

  factory _ProgramKerja.fromJson(Map<String, dynamic> j) => _ProgramKerja(
        id: j['id'] ?? 0,
        namaProgram: j['nama_program'] ?? '',
        bidang: j['bidang'] ?? 'Kurikulum',
        tanggalMulai: j['tanggal_mulai'] ?? '',
        tanggalSelesai: j['tanggal_selesai'],
        penanggungJawab: j['penanggung_jawab'],
        status: j['status'] ?? 'belum_mulai',
        deskripsi: j['deskripsi'],
      );

  Map<String, dynamic> toJson() => {
        'nama_program': namaProgram,
        'bidang': bidang,
        'tanggal_mulai': tanggalMulai,
        if (tanggalSelesai != null) 'tanggal_selesai': tanggalSelesai,
        if (penanggungJawab != null) 'penanggung_jawab': penanggungJawab,
        'status': status,
        if (deskripsi != null) 'deskripsi': deskripsi,
      };
}

// ─── Constants ───────────────────────────────────────────────────────────────
const _statusConfig = {
  'belum_mulai':    {'label': 'Belum Mulai',      'icon': '⏳', 'color': Colors.grey},
  'sedang_berjalan':{'label': 'Sedang Berjalan',   'icon': '🔄', 'color': Colors.blue},
  'selesai':        {'label': 'Selesai',           'icon': '✅', 'color': Colors.green},
  'ditunda':        {'label': 'Ditunda',           'icon': '⚠️', 'color': Colors.orange},
};

const _bidangOptions = ['Kurikulum', 'Kesiswaan', 'Sarana & Prasarana', 'Humas', 'Lainnya'];

// ─── Screen ──────────────────────────────────────────────────────────────────
class ProgramKerjaScreen extends StatefulWidget {
  const ProgramKerjaScreen({super.key});

  @override
  State<ProgramKerjaScreen> createState() => _ProgramKerjaScreenState();
}

class _ProgramKerjaScreenState extends State<ProgramKerjaScreen> {
  late final DioClient _dio;
  List<_ProgramKerja> _list = [];
  bool _loading = false;
  String? _error;
  String _filterStatus = '';
  String _filterBidang = '';

  @override
  void initState() {
    super.initState();
    _dio = sl<DioClient>();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.get(ApiEndpoints.wakilProgramKerja);
      final raw = res.data;
      final rows = raw is List ? raw : (raw is Map ? raw['data'] ?? [] : []);
      setState(() => _list = (rows as List).map((e) => _ProgramKerja.fromJson(Map<String, dynamic>.from(e))).toList());
    } catch (_) {
      setState(() => _error = 'Gagal memuat program kerja');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(_ProgramKerja item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Program Kerja'),
        content: Text('Hapus "${item.namaProgram}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _dio.delete('${ApiEndpoints.wakilProgramKerja}/${item.id}');
      _showSnack('Program kerja berhasil dihapus', Colors.green);
      _load();
    } catch (_) {
      _showSnack('Gagal menghapus', Colors.red);
    }
  }

  void _openForm({_ProgramKerja? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProgramKerjaForm(
        item: item,
        dio: _dio,
        onSaved: _load,
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      const m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]} ${d.year}';
    } catch (_) { return raw; }
  }

  Color _bidangColor(String b) {
    switch (b) {
      case 'Kurikulum': return Colors.blue;
      case 'Kesiswaan': return Colors.purple;
      case 'Sarana & Prasarana': return Colors.green;
      case 'Humas': return Colors.pink;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _list.where((d) {
      if (_filterStatus.isNotEmpty && d.status != _filterStatus) return false;
      if (_filterBidang.isNotEmpty && d.bidang != _filterBidang) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Program Kerja', style: TextStyle(fontSize: 16)),
          Text('Wakil Kepala Sekolah', style: TextStyle(fontSize: 11, color: Colors.white70)),
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
                  const SizedBox(height: 8),
                  Text(_error!),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
                ]))
              : Column(children: [
                  // Stats
                  Container(
                    color: const Color(0xFFEA580C),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: _statusConfig.entries.map((e) {
                        final count = _list.where((d) => d.status == e.key).length;
                        return Expanded(child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          child: Column(children: [
                            Text('$count', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(e.value['label'] as String, style: const TextStyle(color: Colors.white70, fontSize: 8), textAlign: TextAlign.center, maxLines: 2),
                          ]),
                        ));
                      }).toList(),
                    ),
                  ),
                  // Filters
                  Container(
                    color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(child: DropdownButtonFormField<String>(
                        value: _filterStatus.isEmpty ? null : _filterStatus,
                        decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Semua Status')),
                          ..._statusConfig.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['label'] as String))),
                        ],
                        onChanged: (v) => setState(() => _filterStatus = v ?? ''),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: DropdownButtonFormField<String>(
                        value: _filterBidang.isEmpty ? null : _filterBidang,
                        decoration: InputDecoration(labelText: 'Bidang', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Semua Bidang')),
                          ..._bidangOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                        ],
                        onChanged: (v) => setState(() => _filterBidang = v ?? ''),
                      )),
                    ]),
                  ),
                  // List
                  Expanded(child: filtered.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.work_outline, size: 60, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(_list.isEmpty ? 'Belum ada program kerja' : 'Tidak ada yang sesuai filter', style: const TextStyle(color: Colors.grey)),
                        ]))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(0xFFEA580C),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              final cfg = _statusConfig[item.status] ?? _statusConfig['belum_mulai']!;
                              final sColor = cfg['color'] as Color;
                              final bColor = _bidangColor(item.bidang);
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text(item.namaProgram, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                      PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'edit') _openForm(item: item);
                                          if (val == 'delete') _delete(item);
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                                        ],
                                        child: const Icon(Icons.more_vert, color: Colors.grey),
                                      ),
                                    ]),
                                    const SizedBox(height: 8),
                                    Wrap(spacing: 6, children: [
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: bColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(item.bidang, style: TextStyle(fontSize: 11, color: bColor, fontWeight: FontWeight.w600))),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: sColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text('${cfg['icon']} ${cfg['label']}', style: TextStyle(fontSize: 11, color: sColor, fontWeight: FontWeight.w600))),
                                    ]),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('${_fmtDate(item.tanggalMulai)} — ${_fmtDate(item.tanggalSelesai)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ]),
                                    if (item.penanggungJawab?.isNotEmpty == true) ...[
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(Icons.person_outline, size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(item.penanggungJawab!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ]),
                                    ],
                                    if (item.deskripsi?.isNotEmpty == true) ...[
                                      const SizedBox(height: 6),
                                      Text(item.deskripsi!, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                  ]),
                                ),
                              );
                            },
                          ),
                        )),
                ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFFEA580C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── Form ─────────────────────────────────────────────────────────────────────
class _ProgramKerjaForm extends StatefulWidget {
  final _ProgramKerja? item;
  final DioClient dio;
  final VoidCallback onSaved;
  const _ProgramKerjaForm({this.item, required this.dio, required this.onSaved});

  @override
  State<_ProgramKerjaForm> createState() => _ProgramKerjaFormState();
}

class _ProgramKerjaFormState extends State<_ProgramKerjaForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _pjCtrl;
  late final TextEditingController _descCtrl;
  String _bidang = 'Kurikulum';
  String _status = 'belum_mulai';
  String _mulai = '';
  String _selesai = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _namaCtrl = TextEditingController(text: it?.namaProgram ?? '');
    _pjCtrl   = TextEditingController(text: it?.penanggungJawab ?? '');
    _descCtrl = TextEditingController(text: it?.deskripsi ?? '');
    _bidang   = it?.bidang ?? 'Kurikulum';
    _status   = it?.status ?? 'belum_mulai';
    _mulai    = it?.tanggalMulai ?? '';
    _selesai  = it?.tanggalSelesai ?? '';
  }

  @override
  void dispose() {
    _namaCtrl.dispose(); _pjCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isMulai) async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null) {
      final s = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
      setState(() { if (isMulai) _mulai = s; else _selesai = s; });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _mulai.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tanggal mulai wajib diisi!')));
      return;
    }
    setState(() => _loading = true);
    final data = {
      'nama_program': _namaCtrl.text.trim(),
      'bidang': _bidang,
      'tanggal_mulai': _mulai,
      if (_selesai.isNotEmpty) 'tanggal_selesai': _selesai,
      if (_pjCtrl.text.trim().isNotEmpty) 'penanggung_jawab': _pjCtrl.text.trim(),
      'status': _status,
      if (_descCtrl.text.trim().isNotEmpty) 'deskripsi': _descCtrl.text.trim(),
    };
    try {
      if (widget.item != null) {
        await widget.dio.put('${ApiEndpoints.wakilProgramKerja}/${widget.item!.id}', data: data);
      } else {
        await widget.dio.post(ApiEndpoints.wakilProgramKerja, data: data);
      }
      widget.onSaved();
      if (mounted) { Navigator.pop(context); _showSnack('Berhasil disimpan!', Colors.green); }
    } catch (_) {
      if (mounted) _showSnack('Gagal menyimpan', Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.item != null ? 'Edit Program Kerja' : 'Tambah Program Kerja', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),
            TextFormField(controller: _namaCtrl, decoration: InputDecoration(labelText: 'Nama Program *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: _bidang, decoration: InputDecoration(labelText: 'Bidang', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), items: _bidangOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(), onChanged: (v) => setState(() => _bidang = v ?? 'Kurikulum')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: InkWell(onTap: () => _pickDate(true), child: InputDecorator(decoration: InputDecoration(labelText: 'Tanggal Mulai *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), child: Text(_mulai.isEmpty ? 'Pilih tanggal' : _mulai, style: TextStyle(color: _mulai.isEmpty ? Colors.grey : null))))),
              const SizedBox(width: 8),
              Expanded(child: InkWell(onTap: () => _pickDate(false), child: InputDecorator(decoration: InputDecoration(labelText: 'Tanggal Selesai', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), child: Text(_selesai.isEmpty ? 'Opsional' : _selesai, style: TextStyle(color: _selesai.isEmpty ? Colors.grey : null))))),
            ]),
            const SizedBox(height: 12),
            TextFormField(controller: _pjCtrl, decoration: InputDecoration(labelText: 'Penanggung Jawab', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 12),
            const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: _statusConfig.entries.map((e) {
              final sel = _status == e.key;
              return ChoiceChip(label: Text('${e.value['icon']} ${e.value['label']}'), selected: sel, selectedColor: (e.value['color'] as Color).withOpacity(0.2), onSelected: (_) => setState(() => _status = e.key));
            }).toList()),
            const SizedBox(height: 12),
            TextFormField(controller: _descCtrl, decoration: InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.item != null ? 'Simpan Perubahan' : 'Tambah Program'),
            )),
          ]),
        ),
      ),
    );
  }
}
