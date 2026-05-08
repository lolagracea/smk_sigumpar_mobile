import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/secure_storage.dart';

class PklProgressReportScreen extends StatefulWidget {
  const PklProgressReportScreen({super.key});
  @override
  State<PklProgressReportScreen> createState() => _PklProgressReportScreenState();
}

class _PklProgressReportScreenState extends State<PklProgressReportScreen> {
  late final DioClient _dio;

  List<Map<String, dynamic>> _kelasList  = [];
  List<Map<String, dynamic>> _siswaList  = [];
  List<Map<String, dynamic>> _progresList = [];

  String _kelasId  = '';
  String _siswaId  = '';
  String _mingguKe = '';
  final _deskripsiCtrl = TextEditingController();
  int?   _editingId;

  bool _loadingKelas   = false;
  bool _loadingSiswa   = false;
  bool _loadingProgres = false;
  bool _saving         = false;

  // Siswa terpilih (untuk payload)
  Map<String, dynamic>? get _selectedSiswa => _siswaList
      .where((s) => s['id'].toString() == _siswaId)
      .isNotEmpty
      ? _siswaList.firstWhere((s) => s['id'].toString() == _siswaId)
      : null;

  // Filtered list berdasarkan siswaId yang dipilih
  List<Map<String, dynamic>> get _filteredProgres {
    if (_siswaId.isEmpty) return _progresList;
    return _progresList
        .where((item) => item['siswa_id'].toString() == _siswaId)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _dio = DioClient(secureStorage: sl<SecureStorage>());
    _loadKelas();
    _loadProgres();
  }

  @override
  void dispose() {
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  // ─── API ─────────────────────────────────────────────────────────────────

  Future<void> _loadKelas() async {
    setState(() => _loadingKelas = true);
    try {
      final r = await _dio.get(ApiEndpoints.vocationalClasses);
      setState(() =>
          _kelasList = List<Map<String, dynamic>>.from(r.data['data'] ?? []));
    } catch (_) {}
    setState(() => _loadingKelas = false);
  }

  Future<void> _loadSiswa(String kelasId) async {
    if (kelasId.isEmpty) {
      setState(() { _siswaList = []; _siswaId = ''; });
      return;
    }
    setState(() => _loadingSiswa = true);
    try {
      final r = await _dio.get(ApiEndpoints.vocationalStudents,
          queryParameters: {'kelas_id': kelasId});
      setState(() =>
          _siswaList = List<Map<String, dynamic>>.from(r.data['data'] ?? []));
    } catch (_) {
      setState(() => _siswaList = []);
    }
    setState(() => _loadingSiswa = false);
  }

  Future<void> _loadProgres() async {
    setState(() => _loadingProgres = true);
    try {
      final r = await _dio.get(ApiEndpoints.pklProgress);
      setState(() =>
          _progresList = List<Map<String, dynamic>>.from(r.data['data'] ?? []));
    } catch (_) {}
    setState(() => _loadingProgres = false);
  }

  // ─── Form Handlers ───────────────────────────────────────────────────────

  void _resetForm() {
    setState(() {
      _siswaId  = '';
      _mingguKe = '';
      _editingId = null;
    });
    _deskripsiCtrl.clear();
  }

  Future<void> _handleSubmit() async {
    if (_siswaId.isEmpty) {
      _snack('Pilih siswa terlebih dahulu', isError: true);
      return;
    }
    if (_mingguKe.trim().isEmpty) {
      _snack('Minggu ke wajib diisi', isError: true);
      return;
    }

    final siswa = _selectedSiswa;
    final payload = {
      'siswa_id': int.tryParse(_siswaId) ?? 0,
      'kelas_id': _kelasId.isNotEmpty ? int.tryParse(_kelasId) : null,
      'nama_siswa':
          siswa?['nama_lengkap'] ?? siswa?['nama_siswa'] ?? '',
      'nisn': siswa?['nisn'] ?? '',
      'minggu_ke': int.tryParse(_mingguKe) ?? 0,
      'deskripsi': _deskripsiCtrl.text,
    };

    setState(() => _saving = true);
    try {
      if (_editingId != null) {
        await _dio.put(
            '${ApiEndpoints.pklProgress}/$_editingId',
            data: payload);
        _snack('Progres PKL berhasil diperbarui');
      } else {
        await _dio.post(ApiEndpoints.pklProgress, data: payload);
        _snack('Progres PKL berhasil disimpan');
      }
      _resetForm();
      await _loadProgres();
    } catch (_) {
      _snack('Gagal menyimpan progres PKL', isError: true);
    }
    setState(() => _saving = false);
  }

  void _handleEdit(Map<String, dynamic> item) {
    setState(() {
      _editingId = item['id'];
      _siswaId   = item['siswa_id']?.toString() ?? '';
      _mingguKe  = item['minggu_ke']?.toString() ?? '';
    });
    _deskripsiCtrl.text = item['deskripsi'] ?? '';
  }

  Future<void> _handleDelete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Progres PKL'),
        content: const Text('Hapus progres PKL ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _dio.delete('${ApiEndpoints.pklProgress}/${item['id']}');
      _snack('Progres PKL berhasil dihapus');
      await _loadProgres();
    } catch (_) {
      _snack('Gagal menghapus progres PKL', isError: true);
    }
  }

  String _getNamaSiswa(Map<String, dynamic> item) {
    final found = _siswaList.where(
        (s) => s['id'].toString() == item['siswa_id'].toString());
    if (found.isNotEmpty) {
      final s = found.first;
      return s['nama_lengkap'] ?? s['nama_siswa'] ?? '';
    }
    return item['nama_siswa'] ?? 'Siswa ID: ${item['siswa_id']}';
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? const Color(0xFF0F1117) : const Color(0xFFF8F9FC);
    final card = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final bdr  = isDark ? const Color(0xFF2D3142) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Progres PKL',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B))),
          Text('Kelola laporan progres mingguan siswa PKL',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey[500])),
        ]),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgres,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [

            // ── Form Card ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: bdr)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingId != null
                        ? 'Edit Progres PKL'
                        : 'Tambah Progres PKL',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF374151)),
                  ),
                  const SizedBox(height: 14),

                  // Baris: Kelas | Siswa | Minggu Ke
                  Row(children: [
                    // Kelas
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Lbl('Kelas', isDark),
                        const SizedBox(height: 6),
                        _Dropdown(
                          value: _kelasId.isEmpty ? null : _kelasId,
                          hint: _loadingKelas
                              ? 'Memuat kelas...'
                              : '-- Pilih Kelas --',
                          items: _kelasList
                              .map((k) => DropdownMenuItem(
                                    value: k['id'].toString(),
                                    child: Text(k['nama_kelas'] ?? '-',
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _kelasId = v ?? '');
                            _loadSiswa(_kelasId);
                          },
                          isDark: isDark,
                        ),
                      ],
                    )),
                    const SizedBox(width: 10),

                    // Siswa
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Lbl('Siswa', isDark),
                        const SizedBox(height: 6),
                        _Dropdown(
                          value: _siswaId.isEmpty ? null : _siswaId,
                          hint: _loadingSiswa
                              ? 'Memuat siswa...'
                              : '-- Pilih Siswa --',
                          items: _siswaList
                              .map((s) => DropdownMenuItem(
                                    value: s['id'].toString(),
                                    child: Text(
                                        s['nama_lengkap'] ??
                                            s['nama_siswa'] ??
                                            '-',
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: _kelasId.isEmpty
                              ? null
                              : (v) =>
                                  setState(() => _siswaId = v ?? ''),
                          isDark: isDark,
                        ),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 12),

                  // Minggu Ke
                  _Lbl('Minggu Ke', isDark),
                  const SizedBox(height: 6),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: _deco('Contoh: 1', isDark),
                    onChanged: (v) => _mingguKe = v,
                    controller: TextEditingController.fromValue(
                      TextEditingValue(
                        text: _mingguKe,
                        selection: TextSelection.collapsed(
                            offset: _mingguKe.length),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Deskripsi
                  _Lbl('Deskripsi Progres', isDark),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _deskripsiCtrl,
                    maxLines: 4,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: _deco(
                        'Tuliskan aktivitas/progres siswa selama minggu ini...',
                        isDark),
                  ),

                  // Info siswa terpilih
                  if (_selectedSiswa != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Siswa terpilih: ${_selectedSiswa!['nama_lengkap'] ?? _selectedSiswa!['nama_siswa'] ?? '-'}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Tombol aksi
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          _saving
                              ? 'Menyimpan...'
                              : _editingId != null
                                  ? 'Update'
                                  : 'Simpan',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (_editingId != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _resetForm,
                        child: const Text('Batal'),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Riwayat Progres PKL ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: bdr)),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Riwayat Progres PKL',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B))),
                        Text('Menampilkan progres yang sudah disimpan.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400])),
                      ],
                    )),
                    TextButton(
                        onPressed: _loadProgres,
                        child: const Text('Refresh')),
                  ]),
                ),
                const Divider(height: 1),
                if (_loadingProgres)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()))
                else if (_filteredProgres.isEmpty)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                          child: Text('Belum ada progres PKL.',
                              style:
                                  TextStyle(color: Colors.grey[400]))))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredProgres.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = _filteredProgres[i];
                      return Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(
                                  _getNamaSiswa(item),
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                child: Text(
                                  'Minggu ${item['minggu_ke']}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D4ED8)),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Text(
                              item['deskripsi'] ?? '-',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey[600]),
                            ),
                            const SizedBox(height: 10),
                            Row(children: [
                              _ActionBtn(
                                  label: 'Edit',
                                  color: const Color(0xFFD97706),
                                  bg: const Color(0xFFFEF3C7),
                                  onTap: () => _handleEdit(item)),
                              const SizedBox(width: 8),
                              _ActionBtn(
                                  label: 'Hapus',
                                  color: const Color(0xFFDC2626),
                                  bg: const Color(0xFFFFEBEB),
                                  onTap: () => _handleDelete(item)),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
              ]),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  InputDecoration _deco(String hint, bool isDark) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : Colors.grey[400]),
        filled: true,
        fillColor: isDark ? const Color(0xFF252836) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3D4155)
                    : const Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3D4155)
                    : const Color(0xFFCBD5E1))),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide:
                BorderSide(color: Color(0xFF2563EB), width: 2)),
      );
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Lbl extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Lbl(this.text, this.isDark);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? Colors.white38 : Colors.grey[500]));
}

class _Dropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final bool isDark;
  const _Dropdown(
      {required this.value,
      required this.hint,
      required this.items,
      required this.onChanged,
      required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          border: Border.all(
              color: isDark
                  ? const Color(0xFF3D4155)
                  : const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(hint,
                style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark ? Colors.white38 : Colors.grey[400])),
            dropdownColor:
                isDark ? const Color(0xFF252836) : Colors.white,
            style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF1E293B)),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color, bg;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.color,
      required this.bg,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
      );
}