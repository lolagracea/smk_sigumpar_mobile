import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/secure_storage.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _dateOnly(dynamic v) {
  if (v == null) return '';
  return v.toString().split('T').first.split(' ').first;
}

String _todayStr() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> _emptyForm() => {
      'kelas_id': '',
      'nama_kelas': '',
      'siswa_id': '',
      'nama_siswa': '',
      'nisn': '',
      'nama_perusahaan': '',
      'alamat': '',
      'posisi': '',
      'deskripsi_pekerjaan': '',
      'pembimbing_industri': '',
      'kontak_pembimbing': '',
      'tanggal': _todayStr(),
      'tanggal_selesai': '',
      'foto_url': '',
    };

// ─── Screen ──────────────────────────────────────────────────────────────────

class LokasiPKLScreen extends StatefulWidget {
  const LokasiPKLScreen({super.key});
  @override
  State<LokasiPKLScreen> createState() => _LokasiPKLScreenState();
}

class _LokasiPKLScreenState extends State<LokasiPKLScreen> {
  late final DioClient _dio;

  // Tab: 'input' | 'rekap'
  String _tab = 'input';

  // Data lists
  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _siswaList = [];
  List<Map<String, dynamic>> _lokasiList = [];

  // Form
  Map<String, dynamic> _form = _emptyForm();
  File? _foto;
  int? _editingId;

  // Filter rekap
  String _filterKelas = '';
  String _filterSiswa = '';
  String _filterMulai = '';
  String _filterSelesai = '';

  // Loading states
  bool _loadingKelas = false;
  bool _loadingSiswa = false;
  bool _loadingLokasi = false;
  bool _saving = false;

  // Controllers (untuk bidang teks)
  final _namaPerusahaanCtrl   = TextEditingController();
  final _alamatCtrl            = TextEditingController();
  final _posisiCtrl            = TextEditingController();
  final _deskripsiCtrl         = TextEditingController();
  final _pembimbingCtrl        = TextEditingController();
  final _kontakCtrl            = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dio = DioClient(secureStorage: sl<SecureStorage>());
    _loadKelas();
    _loadLokasi();
  }

  @override
  void dispose() {
    _namaPerusahaanCtrl.dispose();
    _alamatCtrl.dispose();
    _posisiCtrl.dispose();
    _deskripsiCtrl.dispose();
    _pembimbingCtrl.dispose();
    _kontakCtrl.dispose();
    super.dispose();
  }

  // ─── API ─────────────────────────────────────────────────────────────────

  Future<void> _loadKelas() async {
    setState(() => _loadingKelas = true);
    try {
      final r = await _dio.get(ApiEndpoints.vocationalClasses);
      setState(() => _kelasList =
          List<Map<String, dynamic>>.from(r.data['data'] ?? []));
    } catch (_) {}
    setState(() => _loadingKelas = false);
  }

  Future<void> _loadSiswaByKelas(String kelasId) async {
    if (kelasId.isEmpty) {
      setState(() => _siswaList = []);
      return;
    }
    setState(() => _loadingSiswa = true);
    try {
      final r = await _dio.get(ApiEndpoints.vocationalStudents,
          queryParameters: {'kelas_id': kelasId});
      setState(() => _siswaList =
          List<Map<String, dynamic>>.from(r.data['data'] ?? []));
    } catch (_) {
      setState(() => _siswaList = []);
    }
    setState(() => _loadingSiswa = false);
  }

  Future<void> _loadLokasi() async {
    setState(() => _loadingLokasi = true);
    try {
      final r = await _dio.get(ApiEndpoints.pklLocation);
      setState(() => _lokasiList =
          List<Map<String, dynamic>>.from(r.data['data'] ?? []));
    } catch (_) {}
    setState(() => _loadingLokasi = false);
  }

  // ─── Form Handlers ───────────────────────────────────────────────────────

  void _handleChangeKelas(String? kelasId) {
    final kelas = _kelasList.firstWhere(
        (e) => e['id'].toString() == (kelasId ?? ''), orElse: () => {});
    setState(() {
      _form = {
        ..._form,
        'kelas_id': kelasId ?? '',
        'nama_kelas': kelas['nama_kelas'] ?? '',
        'siswa_id': '',
        'nama_siswa': '',
        'nisn': '',
      };
      _siswaList = [];
    });
    _loadSiswaByKelas(kelasId ?? '');
  }

  void _handleChangeSiswa(String? siswaId) {
    final siswa = _siswaList.firstWhere(
        (e) => e['id'].toString() == (siswaId ?? ''), orElse: () => {});
    setState(() {
      _form = {
        ..._form,
        'siswa_id': siswaId ?? '',
        'nama_siswa': siswa['nama_lengkap'] ?? siswa['nama_siswa'] ?? '',
        'nisn': siswa['nisn'] ?? '',
      };
    });
  }

  void _resetForm() {
    setState(() {
      _form = _emptyForm();
      _foto = null;
      _editingId = null;
      _siswaList = [];
    });
    _namaPerusahaanCtrl.clear();
    _alamatCtrl.clear();
    _posisiCtrl.clear();
    _deskripsiCtrl.clear();
    _pembimbingCtrl.clear();
    _kontakCtrl.clear();
  }

  bool _validateForm() {
    if (_form['kelas_id'].isEmpty) {
      _snack('Pilih kelas terlebih dahulu', isError: true);
      return false;
    }
    if (_form['siswa_id'].isEmpty) {
      _snack('Pilih siswa terlebih dahulu', isError: true);
      return false;
    }
    if (_namaPerusahaanCtrl.text.trim().isEmpty) {
      _snack('Nama perusahaan wajib diisi', isError: true);
      return false;
    }
    if (_form['tanggal'].isEmpty) {
      _snack('Tanggal mulai wajib diisi', isError: true);
      return false;
    }
    final selesai = _form['tanggal_selesai'] as String;
    if (selesai.isNotEmpty && selesai.compareTo(_form['tanggal']) < 0) {
      _snack('Tanggal selesai tidak boleh lebih awal dari tanggal mulai',
          isError: true);
      return false;
    }
    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;
    setState(() => _saving = true);
    try {
      final Map<String, dynamic> fdMap = {
        'kelas_id': _form['kelas_id'],
        'nama_kelas': _form['nama_kelas'],
        'siswa_id': _form['siswa_id'],
        'nama_siswa': _form['nama_siswa'],
        'nisn': _form['nisn'],
        'nama_perusahaan': _namaPerusahaanCtrl.text,
        'alamat': _alamatCtrl.text,
        'posisi': _posisiCtrl.text,
        'deskripsi_pekerjaan': _deskripsiCtrl.text,
        'pembimbing_industri': _pembimbingCtrl.text,
        'kontak_pembimbing': _kontakCtrl.text,
        'tanggal': _form['tanggal'],
        'tanggal_selesai': _form['tanggal_selesai'],
        'foto_url': _form['foto_url'] ?? '',
      };
      if (_foto != null) {
        fdMap['foto'] = await MultipartFile.fromFile(_foto!.path,
            filename: 'foto_lokasi.jpg');
      }
      final fd = FormData.fromMap(fdMap);

      if (_editingId != null) {
        await _dio.putFormData(
            '${ApiEndpoints.pklLocation}/$_editingId',
            formData: fd);
        _snack('Lokasi PKL berhasil diperbarui');
      } else {
        await _dio.postFormData(ApiEndpoints.pklLocation, formData: fd);
        _snack('Lokasi PKL berhasil disimpan');
      }
      _resetForm();
      await _loadLokasi();
    } catch (_) {
      _snack('Gagal menyimpan lokasi PKL', isError: true);
    }
    setState(() => _saving = false);
  }

  void _handleEdit(Map<String, dynamic> item) {
    setState(() {
      _editingId = item['id'];
      _form = {
        'kelas_id': item['kelas_id']?.toString() ?? '',
        'nama_kelas': item['nama_kelas'] ?? '',
        'siswa_id': item['siswa_id']?.toString() ?? '',
        'nama_siswa': item['nama_siswa'] ?? '',
        'nisn': item['nisn'] ?? '',
        'tanggal':
            _dateOnly(item['tanggal']).isEmpty ? _todayStr() : _dateOnly(item['tanggal']),
        'tanggal_selesai': _dateOnly(item['tanggal_selesai']),
        'foto_url': item['foto_url'] ?? '',
      };
      _foto = null;
      _tab = 'input';
    });
    _namaPerusahaanCtrl.text = item['nama_perusahaan'] ?? '';
    _alamatCtrl.text = item['alamat'] ?? '';
    _posisiCtrl.text = item['posisi'] ?? '';
    _deskripsiCtrl.text = item['deskripsi_pekerjaan'] ?? '';
    _pembimbingCtrl.text = item['pembimbing_industri'] ?? '';
    _kontakCtrl.text = item['kontak_pembimbing'] ?? '';
    if ((_form['kelas_id'] as String).isNotEmpty) {
      _loadSiswaByKelas(_form['kelas_id']);
    }
  }

  Future<void> _handleDelete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Lokasi PKL'),
        content: Text(
            'Hapus data PKL ${item['nama_siswa'] ?? ''} di ${item['nama_perusahaan'] ?? ''}?'),
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
      await _dio.delete('${ApiEndpoints.pklLocation}/${item['id']}');
      _snack('Lokasi PKL berhasil dihapus');
      await _loadLokasi();
    } catch (_) {
      _snack('Gagal menghapus lokasi PKL', isError: true);
    }
  }

  Future<void> _pickDate({required bool isSelesai}) async {
    final current = isSelesai ? _form['tanggal_selesai'] : _form['tanggal'];
    final init = DateTime.tryParse(current as String) ?? DateTime.now();
    final p = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (p == null) return;
    final s =
        '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}';
    setState(() => _form = {
          ..._form,
          isSelesai ? 'tanggal_selesai' : 'tanggal': s,
        });
  }

  Future<void> _pickFoto() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _foto = File(img.path));
  }

  List<Map<String, dynamic>> get _filteredRekap => _lokasiList.where((item) {
        final itemTanggal = _dateOnly(item['tanggal']);
        if (_filterKelas.isNotEmpty &&
            item['kelas_id'].toString() != _filterKelas) return false;
        if (_filterSiswa.isNotEmpty &&
            item['siswa_id'].toString() != _filterSiswa) return false;
        if (_filterMulai.isNotEmpty &&
            itemTanggal.compareTo(_filterMulai) < 0) return false;
        if (_filterSelesai.isNotEmpty &&
            itemTanggal.compareTo(_filterSelesai) > 0) return false;
        return true;
      }).toList();

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
          Text('Lokasi PKL',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B))),
          Text('Kelola lokasi PKL siswa berdasarkan kelas',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey[500])),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: card,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(children: [
              _TabBtn(
                  label: '✏️  Input Lokasi',
                  active: _tab == 'input',
                  onTap: () => setState(() => _tab = 'input')),
              const SizedBox(width: 8),
              _TabBtn(
                  label: '📊  Rekap',
                  active: _tab == 'rekap',
                  onTap: () => setState(() => _tab = 'rekap')),
            ]),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLokasi,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _tab == 'input'
              ? _buildInput(isDark, card, bdr)
              : _buildRekap(isDark, card, bdr),
        ),
      ),
    );
  }

  // ─── Tab Input ───────────────────────────────────────────────────────────

  Widget _buildInput(bool isDark, Color card, Color bdr) {
    final kelasId = _form['kelas_id'] as String;
    final siswaId = _form['siswa_id'] as String;

    return Column(children: [
      // ── Form Card ──────────────────────────────────────────────
      _Card(
        isDark: isDark, card: card, bdr: bdr,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _editingId != null ? 'Edit Lokasi PKL' : 'Tambah Lokasi PKL',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF374151)),
          ),
          const SizedBox(height: 14),

          // Kelas
          _Lbl('Kelas', isDark),
          const SizedBox(height: 6),
          _Dropdown(
            value: kelasId.isEmpty ? null : kelasId,
            hint: _loadingKelas ? 'Memuat kelas...' : '-- Pilih Kelas --',
            items: _kelasList
                .map((k) => DropdownMenuItem(
                    value: k['id'].toString(),
                    child: Text(k['nama_kelas'] ?? '-')))
                .toList(),
            onChanged: _handleChangeKelas,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Siswa
          _Lbl('Nama Siswa', isDark),
          const SizedBox(height: 6),
          _Dropdown(
            value: siswaId.isEmpty ? null : siswaId,
            hint: _loadingSiswa ? 'Memuat siswa...' : '-- Pilih Siswa --',
            items: _siswaList
                .map((s) => DropdownMenuItem(
                    value: s['id'].toString(),
                    child: Text(
                        s['nama_lengkap'] ?? s['nama_siswa'] ?? '-',
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: kelasId.isEmpty ? null : _handleChangeSiswa,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // NISN (read-only)
          _Lbl('NISN', isDark),
          const SizedBox(height: 6),
          _ReadOnly(
              text: (_form['nisn'] as String).isEmpty
                  ? 'Otomatis terisi'
                  : _form['nisn'],
              isDark: isDark),
          const SizedBox(height: 12),

          // Nama Perusahaan
          _Lbl('Nama Perusahaan', isDark),
          const SizedBox(height: 6),
          _TF(_namaPerusahaanCtrl, 'Contoh: PT Maju Jaya', isDark),
          const SizedBox(height: 12),

          // Posisi
          _Lbl('Posisi', isDark),
          const SizedBox(height: 6),
          _TF(_posisiCtrl, 'Contoh: Teknisi / Admin / Operator', isDark),
          const SizedBox(height: 12),

          // Pembimbing Industri
          _Lbl('Pembimbing Industri', isDark),
          const SizedBox(height: 6),
          _TF(_pembimbingCtrl, 'Nama pembimbing', isDark),
          const SizedBox(height: 12),

          // Kontak Pembimbing
          _Lbl('Kontak Pembimbing', isDark),
          const SizedBox(height: 6),
          _TF(_kontakCtrl, 'No. HP / Email', isDark),
          const SizedBox(height: 12),

          // Tanggal row
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Lbl('Tanggal Mulai', isDark),
                const SizedBox(height: 6),
                _DateBtn(
                    label: (_form['tanggal'] as String).isEmpty
                        ? 'Pilih tanggal'
                        : _form['tanggal'],
                    onTap: () => _pickDate(isSelesai: false),
                    isDark: isDark),
              ],
            )),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Lbl('Est. Tanggal Selesai', isDark),
                const SizedBox(height: 6),
                _DateBtn(
                    label: (_form['tanggal_selesai'] as String).isEmpty
                        ? 'Pilih tanggal'
                        : _form['tanggal_selesai'],
                    onTap: () => _pickDate(isSelesai: true),
                    isDark: isDark),
              ],
            )),
          ]),
          const SizedBox(height: 12),

          // Alamat
          _Lbl('Alamat Perusahaan', isDark),
          const SizedBox(height: 6),
          _TF(_alamatCtrl, 'Alamat lokasi PKL', isDark),
          const SizedBox(height: 12),

          // Foto
          _Lbl('Foto Lokasi', isDark),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickFoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252836)
                    : Colors.white,
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF3D4155)
                        : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('Pilih Foto',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  _foto != null
                      ? _foto!.path.split('/').last
                      : 'Belum ada foto dipilih',
                  style: TextStyle(
                      fontSize: 12,
                      color: _foto != null
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : Colors.grey[400]),
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Deskripsi
          _Lbl('Deskripsi Pekerjaan', isDark),
          const SizedBox(height: 6),
          TextField(
            controller: _deskripsiCtrl,
            maxLines: 3,
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87),
            decoration: _deco(
                'Deskripsikan pekerjaan atau bidang tugas siswa selama PKL...',
                isDark),
          ),
          const SizedBox(height: 16),

          // Buttons
          Row(children: [
            if (_editingId != null) ...[
              Expanded(
                  child: OutlinedButton(
                      onPressed: _resetForm, child: const Text('Batal'))),
              const SizedBox(width: 8),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _saving ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _saving
                      ? 'Menyimpan...'
                      : _editingId != null
                          ? 'Update Lokasi PKL'
                          : 'Simpan Lokasi PKL',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 16),

      // ── Daftar Lokasi PKL ───────────────────────────────────────
      Container(
        decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bdr)),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              Expanded(
                  child: Text('Daftar Lokasi PKL',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B)))),
              TextButton(onPressed: _loadLokasi, child: const Text('Refresh')),
            ]),
          ),
          const Divider(height: 1),
          if (_loadingLokasi)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()))
          else if (_lokasiList.isEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                    child: Text('Belum ada data lokasi PKL.',
                        style: TextStyle(color: Colors.grey[400]))))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lokasiList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final item = _lokasiList[i];
                return Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['nama_siswa'] ?? '-',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B))),
                                Text(item['nisn'] ?? '-',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400])),
                                const SizedBox(height: 2),
                                Text(item['nama_kelas'] ?? '-',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue)),
                              ],
                            )),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(item['nama_perusahaan'] ?? '-',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87)),
                                Text(item['posisi'] ?? '-',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500])),
                              ],
                            ),
                          ]),
                      const SizedBox(height: 6),
                      Text(
                          '${_dateOnly(item['tanggal'])} s/d ${_dateOnly(item['tanggal_selesai'])}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
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
    ]);
  }

  // ─── Tab Rekap ───────────────────────────────────────────────────────────

  Widget _buildRekap(bool isDark, Color card, Color bdr) {
    final filtered = _filteredRekap;
    // Siswa unik dari lokasiList (filtered by kelas jika dipilih)
    final siswaOpts = _lokasiList
        .where((item) =>
            _filterKelas.isEmpty ||
            item['kelas_id'].toString() == _filterKelas)
        .toList();

    return Column(children: [
      // ── Filter ─────────────────────────────────────────────────
      _Card(
        isDark: isDark, card: card, bdr: bdr,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rekap Lokasi PKL',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF374151))),
          const SizedBox(height: 12),

          // Filter Kelas
          _Lbl('Kelas', isDark),
          const SizedBox(height: 6),
          _Dropdown(
            value: _filterKelas.isEmpty ? null : _filterKelas,
            hint: 'Semua Kelas',
            items: [
              const DropdownMenuItem(value: '', child: Text('Semua Kelas')),
              ..._kelasList.map((k) => DropdownMenuItem(
                  value: k['id'].toString(),
                  child: Text(k['nama_kelas'] ?? '-'))),
            ],
            onChanged: (v) => setState(
                () => {_filterKelas = v ?? '', _filterSiswa = ''}),
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Filter Siswa
          _Lbl('Siswa', isDark),
          const SizedBox(height: 6),
          _Dropdown(
            value: _filterSiswa.isEmpty ? null : _filterSiswa,
            hint: 'Semua Siswa',
            items: [
              const DropdownMenuItem(value: '', child: Text('Semua Siswa')),
              ...siswaOpts.map((item) => DropdownMenuItem(
                  value: item['siswa_id'].toString(),
                  child: Text(item['nama_siswa'] ?? '-',
                      overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (v) => setState(() => _filterSiswa = v ?? ''),
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Filter Tanggal
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Lbl('Tanggal Mulai', isDark),
                const SizedBox(height: 6),
                _DateBtn(
                    label: _filterMulai.isEmpty ? 'Semua' : _filterMulai,
                    onTap: () async {
                      final p = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030));
                      if (p != null) {
                        setState(() => _filterMulai =
                            '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}');
                      }
                    },
                    isDark: isDark),
              ],
            )),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Lbl('Tanggal Akhir', isDark),
                const SizedBox(height: 6),
                _DateBtn(
                    label: _filterSelesai.isEmpty ? 'Semua' : _filterSelesai,
                    onTap: () async {
                      final p = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030));
                      if (p != null) {
                        setState(() => _filterSelesai =
                            '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}');
                      }
                    },
                    isDark: isDark),
              ],
            )),
          ]),

          if (_filterKelas.isNotEmpty ||
              _filterSiswa.isNotEmpty ||
              _filterMulai.isNotEmpty ||
              _filterSelesai.isNotEmpty) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => setState(() {
                _filterKelas = '';
                _filterSiswa = '';
                _filterMulai = '';
                _filterSelesai = '';
              }),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Reset Filter'),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 16),

      // ── Tabel Rekap ────────────────────────────────────────────
      Container(
        decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bdr)),
        child: filtered.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                    child: Text('Tidak ada data rekap lokasi PKL.',
                        style: TextStyle(color: Colors.grey[400]))))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(item['nama_kelas'] ?? '-',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D4ED8))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  '${i + 1}. ${item['nama_siswa'] ?? '-'}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B)))),
                        ]),
                        const SizedBox(height: 4),
                        Text(item['nisn'] ?? '-',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400])),
                        const SizedBox(height: 6),
                        _InfoRow('Perusahaan',
                            item['nama_perusahaan'] ?? '-', isDark),
                        _InfoRow('Posisi', item['posisi'] ?? '-', isDark),
                        _InfoRow(
                            'Pembimbing',
                            '${item['pembimbing_industri'] ?? '-'} (${item['kontak_pembimbing'] ?? '-'})',
                            isDark),
                        _InfoRow(
                            'Periode',
                            '${_dateOnly(item['tanggal'])} s/d ${_dateOnly(item['tanggal_selesai'])}',
                            isDark),
                      ],
                    ),
                  );
                },
              ),
      ),
      const SizedBox(height: 24),
    ]);
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
            borderSide: BorderSide(color: Color(0xFF2563EB), width: 2)),
      );
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF2563EB)
                : Colors.grey.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : Colors.grey[600])),
        ),
      );
}

class _Card extends StatelessWidget {
  final bool isDark;
  final Color card, bdr;
  final Widget child;
  const _Card(
      {required this.isDark,
      required this.card,
      required this.bdr,
      required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bdr)),
        child: child,
      );
}

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
                    color: isDark ? Colors.white38 : Colors.grey[400])),
            dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF1E293B)),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
}

class _TF extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool isDark;
  const _TF(this.ctrl, this.hint, this.isDark);

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
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
        ),
      );
}

class _ReadOnly extends StatelessWidget {
  final String text;
  final bool isDark;
  const _ReadOnly({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E2030)
              : const Color(0xFFF8FAFC),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF3D4155)
                  : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      );
}

class _DateBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  const _DateBtn(
      {required this.label, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            border: Border.all(
                color: isDark
                    ? const Color(0xFF3D4155)
                    : const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87)),
          ]),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _InfoRow(this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 90,
              child: Text('$label:',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey[500]))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87))),
        ]),
      );
}
