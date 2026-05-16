import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/secure_storage.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _getPredikat(double nilai) {
  if (nilai >= 90) return 'Sangat Baik';
  if (nilai >= 80) return 'Baik';
  if (nilai >= 70) return 'Cukup';
  return 'Perlu Bimbingan';
}

Color _getPredikatColor(double nilai) {
  if (nilai >= 90) return const Color(0xFF16A34A);
  if (nilai >= 80) return const Color(0xFF2563EB);
  if (nilai >= 70) return const Color(0xFFD97706);
  return const Color(0xFFDC2626);
}

Color _getPredikatBg(double nilai) {
  if (nilai >= 90) return const Color(0xFFDCFCE7);
  if (nilai >= 80) return const Color(0xFFEFF6FF);
  if (nilai >= 70) return const Color(0xFFFEF3C7);
  return const Color(0xFFFFEBEB);
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class NilaiPKLScreen extends StatefulWidget {
  const NilaiPKLScreen({super.key});
  @override
  State<NilaiPKLScreen> createState() => _NilaiPKLScreenState();
}

class _NilaiPKLScreenState extends State<NilaiPKLScreen>
    with SingleTickerProviderStateMixin {
  late final DioClient _dio;
  late final TabController _tabController;

  // ── Data Kelas ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _kelasList = [];
  bool _loadingKelas = false;

  // ── Tab INPUT ─────────────────────────────────────────────────────────────
  String _selectedKelas = '';
  List<Map<String, dynamic>> _siswaList = [];
  Map<String, Map<String, dynamic>> _nilaiMap = {};
  int _bobotPraktik = 50;
  int _bobotSikap   = 30;
  int _bobotLaporan = 20;
  bool _loadingSiswa = false;
  bool _saving       = false;

  late TextEditingController _bobotPraktikCtrl;
  late TextEditingController _bobotSikapCtrl;
  late TextEditingController _bobotLaporanCtrl;
  final Map<String, Map<String, TextEditingController>> _nilaiControllers = {};

  // ── Tab RIWAYAT ───────────────────────────────────────────────────────────
  // Riwayat disimpan lokal setelah berhasil simpan, berisi snapshot nilaiMap
  List<Map<String, dynamic>> _riwayatData = [];
  bool _exportingExcel = false;

  // Kelas & waktu simpan terakhir (untuk header riwayat)
  String _riwayatNamaKelas = '';
  String _riwayatWaktuSimpan = '';

  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic>? get _selectedKelasObj => _kelasList
      .where((k) => k['id'].toString() == _selectedKelas)
      .isNotEmpty
      ? _kelasList.firstWhere((k) => k['id'].toString() == _selectedKelas)
      : null;

  int get _totalBobot => _bobotPraktik + _bobotSikap + _bobotLaporan;

  double _hitungNilaiAkhir(Map<String, dynamic> row) {
    final praktik = double.tryParse(row['nilai_praktik']?.toString() ?? '') ?? 0;
    final sikap   = double.tryParse(row['nilai_sikap']?.toString() ?? '')   ?? 0;
    final laporan = double.tryParse(row['nilai_laporan']?.toString() ?? '') ?? 0;
    return (praktik * (_bobotPraktik / 100)) +
        (sikap   * (_bobotSikap   / 100)) +
        (laporan * (_bobotLaporan / 100));
  }

  Map<String, dynamic> get _summary {
    int sudahLengkap = 0, belumLengkap = 0;
    double totalNilai = 0;
    for (final siswa in _siswaList) {
      final row     = _nilaiMap[siswa['id'].toString()] ?? {};
      final praktik = row['nilai_praktik']?.toString() ?? '';
      final sikap   = row['nilai_sikap']?.toString()   ?? '';
      final laporan = row['nilai_laporan']?.toString() ?? '';
      if (praktik.isNotEmpty && sikap.isNotEmpty && laporan.isNotEmpty) {
        sudahLengkap++;
        totalNilai += _hitungNilaiAkhir(row);
      } else {
        belumLengkap++;
      }
    }
    return {
      'totalSiswa'   : _siswaList.length,
      'sudahLengkap' : sudahLengkap,
      'belumLengkap' : belumLengkap,
      'rataRata'     : sudahLengkap > 0
          ? double.parse((totalNilai / sudahLengkap).toStringAsFixed(2))
          : 0.0,
    };
  }

  @override
  void initState() {
    super.initState();
    _dio = DioClient(secureStorage: sl<SecureStorage>());
    _tabController = TabController(length: 2, vsync: this);
    _bobotPraktikCtrl = TextEditingController(text: '50');
    _bobotSikapCtrl   = TextEditingController(text: '30');
    _bobotLaporanCtrl = TextEditingController(text: '20');
    _loadKelas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bobotPraktikCtrl.dispose();
    _bobotSikapCtrl.dispose();
    _bobotLaporanCtrl.dispose();
    for (final entry in _nilaiControllers.entries) {
      for (final ctrl in entry.value.values) { ctrl.dispose(); }
    }
    super.dispose();
  }

  // ── Controllers nilai per-siswa ───────────────────────────────────────────

  TextEditingController _getNilaiCtrl(String siswaId, String field) {
    _nilaiControllers[siswaId] ??= {};
    if (!_nilaiControllers[siswaId]!.containsKey(field)) {
      final initial = _nilaiMap[siswaId]?[field]?.toString() ?? '';
      final ctrl    = TextEditingController(text: initial);
      ctrl.addListener(() => _updateNilai(siswaId, field, ctrl.text));
      _nilaiControllers[siswaId]![field] = ctrl;
    }
    return _nilaiControllers[siswaId]![field]!;
  }

  TextEditingController _getCatatanCtrl(String siswaId) =>
      _getNilaiCtrl(siswaId, 'catatan');

  // ── API ───────────────────────────────────────────────────────────────────

  Future<void> _loadKelas() async {
    setState(() => _loadingKelas = true);
    try {
      final r = await _dio.get(ApiEndpoints.vocationalClasses);
      setState(() =>
          _kelasList = List<Map<String, dynamic>>.from(r.data['data'] ?? []));
    } catch (_) {}
    setState(() => _loadingKelas = false);
  }

  Future<void> _loadSiswaDanNilai(String kelasId) async {
    if (kelasId.isEmpty) {
      setState(() { _siswaList = []; _nilaiMap = {}; });
      return;
    }
    setState(() => _loadingSiswa = true);
    try {
      final results = await Future.wait([
        _dio.get(ApiEndpoints.vocationalStudents,
            queryParameters: {'kelas_id': kelasId}),
        _dio.get(ApiEndpoints.pklGrades,
            queryParameters: {'kelas_id': kelasId}),
      ]);

      final siswa = List<Map<String, dynamic>>.from(results[0].data['data'] ?? []);
      final nilai = List<Map<String, dynamic>>.from(results[1].data['data'] ?? []);

      final Map<String, Map<String, dynamic>> nilaiBySiswa = {};
      for (final n in nilai) {
        nilaiBySiswa[n['siswa_id'].toString()] = n;
      }

      final Map<String, Map<String, dynamic>> nextMap = {};
      for (final s in siswa) {
        final sid      = s['id'].toString();
        final existing = nilaiBySiswa[sid];
        nextMap[sid] = {
          'siswa_id'     : s['id'],
          'nama_siswa'   : s['nama_lengkap'] ?? s['nama_siswa'] ?? '-',
          'nisn'         : s['nisn'] ?? '',
          'nilai_praktik': existing?['nilai_praktik']?.toString() ?? '',
          'nilai_sikap'  : existing?['nilai_sikap']?.toString()   ?? '',
          'nilai_laporan': existing?['nilai_laporan']?.toString() ?? '',
          'catatan'      : existing?['catatan'] ?? '',
        };
      }

      for (final entry in _nilaiControllers.entries) {
        for (final ctrl in entry.value.values) { ctrl.dispose(); }
      }
      _nilaiControllers.clear();

      setState(() { _siswaList = siswa; _nilaiMap = nextMap; });

      for (final s in siswa) {
        final sid = s['id'].toString();
        for (final field in ['nilai_praktik', 'nilai_sikap', 'nilai_laporan', 'catatan']) {
          final ctrl = TextEditingController(text: nextMap[sid]?[field]?.toString() ?? '');
          ctrl.addListener(() => _updateNilai(sid, field, ctrl.text));
          _nilaiControllers[sid] ??= {};
          _nilaiControllers[sid]![field] = ctrl;
        }
      }
    } catch (_) {
      setState(() { _siswaList = []; _nilaiMap = {}; });
    }
    setState(() => _loadingSiswa = false);
  }

  void _updateNilai(String siswaId, String field, String value) {
    setState(() {
      _nilaiMap[siswaId] = { ...(_nilaiMap[siswaId] ?? {}), field: value };
    });
  }

  bool _validateNilai() {
    if (_selectedKelas.isEmpty) {
      _snack('Pilih kelas terlebih dahulu', isError: true); return false;
    }
    if (_siswaList.isEmpty) {
      _snack('Tidak ada siswa di kelas ini', isError: true); return false;
    }
    if (_totalBobot != 100) {
      _snack('Total bobot harus 100%', isError: true); return false;
    }
    for (final siswa in _siswaList) {
      final sid  = siswa['id'].toString();
      final row  = _nilaiMap[sid] ?? {};
      final nama = row['nama_siswa'] ?? siswa['nama_lengkap'] ?? 'siswa';
      for (final field in ['nilai_praktik', 'nilai_sikap', 'nilai_laporan']) {
        final val = row[field]?.toString() ?? '';
        if (val.isEmpty) {
          _snack('Nilai $nama belum lengkap', isError: true); return false;
        }
        final n = double.tryParse(val);
        if (n == null || n < 0 || n > 100) {
          _snack('Semua nilai harus angka antara 0–100', isError: true); return false;
        }
      }
    }
    return true;
  }

  Future<void> _handleSimpan() async {
    if (!_validateNilai()) return;

    final payload = {
      'kelas_id': _selectedKelas,
      'bobot': {
        'praktik': _bobotPraktik,
        'sikap'  : _bobotSikap,
        'laporan': _bobotLaporan,
      },
      'data_nilai': _siswaList.map((siswa) {
        final sid = siswa['id'].toString();
        final row = _nilaiMap[sid] ?? {};
        return {
          'siswa_id'     : siswa['id'],
          'nama_siswa'   : row['nama_siswa'] ?? '',
          'nisn'         : row['nisn'] ?? '',
          'nilai_praktik': double.tryParse(row['nilai_praktik']?.toString() ?? '') ?? 0,
          'nilai_sikap'  : double.tryParse(row['nilai_sikap']?.toString()   ?? '') ?? 0,
          'nilai_laporan': double.tryParse(row['nilai_laporan']?.toString() ?? '') ?? 0,
          'catatan'      : row['catatan'] ?? '',
        };
      }).toList(),
    };

    setState(() => _saving = true);
    try {
      await _dio.post(ApiEndpoints.pklGrades, data: payload);
      _snack('Nilai PKL berhasil disimpan');

      // ── Snapshot ke riwayat ──────────────────────────────────────────────
      final now = DateTime.now();
      final snap = <Map<String, dynamic>>[];
      for (final siswa in _siswaList) {
        final sid = siswa['id'].toString();
        final row = _nilaiMap[sid] ?? {};
        snap.add({
          'nama_siswa'   : row['nama_siswa'] ?? siswa['nama_lengkap'] ?? '-',
          'nisn'         : row['nisn'] ?? siswa['nisn'] ?? '-',
          'nilai_praktik': row['nilai_praktik']?.toString() ?? '0',
          'nilai_sikap'  : row['nilai_sikap']?.toString()   ?? '0',
          'nilai_laporan': row['nilai_laporan']?.toString()  ?? '0',
          'catatan'      : row['catatan'] ?? '',
          'bobot_praktik': _bobotPraktik,
          'bobot_sikap'  : _bobotSikap,
          'bobot_laporan': _bobotLaporan,
          'saved_at'     : now.toIso8601String(),
        });
      }

      setState(() {
        _riwayatData        = snap;
        _riwayatNamaKelas   = _selectedKelasObj?['nama_kelas'] ?? '-';
        _riwayatWaktuSimpan =
            '${_pad(now.day)}/${_pad(now.month)}/${now.year}  '
            '${_pad(now.hour)}:${_pad(now.minute)}';
      });

      await _loadSiswaDanNilai(_selectedKelas);
    } catch (_) {
      _snack('Gagal menyimpan nilai PKL', isError: true);
    }
    setState(() => _saving = false);
  }

  void _handleReset() {
    setState(() {
      _bobotPraktik = 50; _bobotSikap = 30; _bobotLaporan = 20;
      _bobotPraktikCtrl.text = '50';
      _bobotSikapCtrl.text   = '30';
      _bobotLaporanCtrl.text = '20';
    });
    _loadSiswaDanNilai(_selectedKelas);
  }

  // ── Export Excel ──────────────────────────────────────────────────────────

  Future<void> _handleExportExcel() async {
    if (_riwayatData.isEmpty) {
      _snack('Tidak ada data untuk diekspor', isError: true);
      return;
    }
    setState(() => _exportingExcel = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Nilai PKL'];
      excel.delete('Sheet1');

      final now = DateTime.now();
      final tglEkspor =
          '${_pad(now.day)}/${_pad(now.month)}/${now.year}  ${_pad(now.hour)}:${_pad(now.minute)}';

      _cell(sheet, 0, 0, 'REKAP NILAI PKL', bold: true, fontSize: 14);
      _cell(sheet, 1, 0, 'Kelas: $_riwayatNamaKelas');
      _cell(sheet, 2, 0, 'Disimpan: $_riwayatWaktuSimpan');
      _cell(sheet, 3, 0, 'Diekspor: $tglEkspor');
      _cell(sheet, 4, 0, '');

      final bobot = _riwayatData.isNotEmpty ? _riwayatData.first : {};
      _cell(sheet, 5, 0,
          'Bobot: Praktik ${bobot['bobot_praktik'] ?? _bobotPraktik}%  |  '
          'Sikap ${bobot['bobot_sikap'] ?? _bobotSikap}%  |  '
          'Laporan ${bobot['bobot_laporan'] ?? _bobotLaporan}%');
      _cell(sheet, 6, 0, '');

      final headers = [
        'No', 'Nama Siswa', 'NISN',
        'Nilai Praktik', 'Nilai Sikap', 'Nilai Laporan',
        'Nilai Akhir', 'Predikat', 'Catatan',
        'Waktu Simpan',
      ];
      for (var col = 0; col < headers.length; col++) {
        _cell(sheet, 7, col, headers[col], bold: true, isHeader: true);
      }

      for (var i = 0; i < _riwayatData.length; i++) {
        final item    = _riwayatData[i];
        final bp      = item['bobot_praktik'] ?? _bobotPraktik;
        final bs      = item['bobot_sikap']   ?? _bobotSikap;
        final bl      = item['bobot_laporan'] ?? _bobotLaporan;
        final praktik = double.tryParse(item['nilai_praktik']?.toString() ?? '') ?? 0;
        final sikap   = double.tryParse(item['nilai_sikap']?.toString()   ?? '') ?? 0;
        final laporan = double.tryParse(item['nilai_laporan']?.toString() ?? '') ?? 0;
        final akhir   = (praktik * bp / 100) + (sikap * bs / 100) + (laporan * bl / 100);

        String waktuSimpan = '-';
        final savedAt = item['saved_at']?.toString() ?? '';
        if (savedAt.isNotEmpty) {
          try {
            final dt = DateTime.parse(savedAt).toLocal();
            waktuSimpan =
                '${_pad(dt.day)}/${_pad(dt.month)}/${dt.year} ${_pad(dt.hour)}:${_pad(dt.minute)}';
          } catch (_) {}
        }

        final row = 8 + i;
        _cell(sheet, row, 0, '${i + 1}');
        _cell(sheet, row, 1, item['nama_siswa']?.toString()   ?? '-');
        _cell(sheet, row, 2, item['nisn']?.toString()         ?? '-');
        _cell(sheet, row, 3, praktik.toStringAsFixed(1));
        _cell(sheet, row, 4, sikap.toStringAsFixed(1));
        _cell(sheet, row, 5, laporan.toStringAsFixed(1));
        _cell(sheet, row, 6, akhir.toStringAsFixed(2));
        _cell(sheet, row, 7, _getPredikat(akhir));
        _cell(sheet, row, 8, item['catatan']?.toString()      ?? '-');
        _cell(sheet, row, 9, waktuSimpan);
      }

      sheet.setColumnWidth(0, 5);
      sheet.setColumnWidth(1, 28);
      sheet.setColumnWidth(2, 18);
      sheet.setColumnWidth(3, 14);
      sheet.setColumnWidth(4, 14);
      sheet.setColumnWidth(5, 14);
      sheet.setColumnWidth(6, 14);
      sheet.setColumnWidth(7, 18);
      sheet.setColumnWidth(8, 35);
      sheet.setColumnWidth(9, 20);

      final dir = await getApplicationDocumentsDirectory();
      final ts  = '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}';
      final fileName = 'Nilai_PKL_${_riwayatNamaKelas.replaceAll(' ', '_')}_$ts.xlsx';
      final filePath = '${dir.path}/$fileName';

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Gagal encode Excel');
      await File(filePath).writeAsBytes(bytes);

      _snack('File disimpan: $fileName');
      await OpenFilex.open(filePath);
    } catch (e) {
      _snack('Gagal mengekspor: $e', isError: true);
    }
    setState(() => _exportingExcel = false);
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _cell(Sheet sheet, int row, int col, String value,
      {bool bold = false, bool isHeader = false, double fontSize = 11}) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      bold: bold || isHeader,
      fontSize: fontSize.toInt(),
      backgroundColorHex:
          isHeader ? ExcelColor.fromHexString('#2563EB') : ExcelColor.none,
      fontColorHex:
          isHeader ? ExcelColor.fromHexString('#FFFFFF') : ExcelColor.none,
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
          Text('Nilai PKL',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B))),
          Text('Input dan riwayat nilai PKL siswa',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey[500])),
        ]),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey[500],
          indicatorColor: const Color(0xFF2563EB),
          tabs: [
            const Tab(icon: Icon(Icons.edit_note), text: 'Input Nilai'),
            Tab(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.history),
                  if (_riwayatData.isNotEmpty)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_riwayatData.length}',
                          style: const TextStyle(fontSize: 8, color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              text: 'Riwayat',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInputTab(isDark, card, bdr),
          _buildRiwayatTab(isDark, card, bdr),
        ],
      ),
    );
  }

  // ── TAB INPUT ─────────────────────────────────────────────────────────────

  Widget _buildInputTab(bool isDark, Color card, Color bdr) {
    final sum = _summary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // Header: Kelas + Bobot + Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bdr)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Lbl('Kelas', isDark),
                const SizedBox(height: 6),
                _Dropdown(
                  value: _selectedKelas.isEmpty ? null : _selectedKelas,
                  hint: _loadingKelas ? 'Memuat kelas...' : '-- Pilih Kelas --',
                  items: _kelasList.map((k) => DropdownMenuItem(
                    value: k['id'].toString(),
                    child: Text(k['nama_kelas'] ?? '-', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) {
                    setState(() => _selectedKelas = v ?? '');
                    _loadSiswaDanNilai(_selectedKelas);
                  },
                  isDark: isDark,
                ),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Lbl('Bobot Praktik', isDark),
                const SizedBox(height: 6),
                _BobotField(ctrl: _bobotPraktikCtrl, isDark: isDark,
                    onChanged: (v) => setState(() => _bobotPraktik = int.tryParse(v) ?? 0)),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Lbl('Bobot Sikap', isDark),
                const SizedBox(height: 6),
                _BobotField(ctrl: _bobotSikapCtrl, isDark: isDark,
                    onChanged: (v) => setState(() => _bobotSikap = int.tryParse(v) ?? 0)),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Lbl('Bobot Laporan', isDark),
                const SizedBox(height: 6),
                _BobotField(ctrl: _bobotLaporanCtrl, isDark: isDark,
                    onChanged: (v) => setState(() => _bobotLaporan = int.tryParse(v) ?? 0)),
              ])),
            ]),
            const SizedBox(height: 14),

            Wrap(spacing: 16, runSpacing: 8, children: [
              _SummaryChip(label: 'Total Bobot', value: '$_totalBobot%',
                  color: _totalBobot == 100
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626)),
              _SummaryChip(label: 'Total Siswa', value: '${sum['totalSiswa']}',
                  color: isDark ? Colors.white70 : Colors.black87),
              _SummaryChip(label: 'Lengkap', value: '${sum['sudahLengkap']}',
                  color: const Color(0xFF16A34A)),
              _SummaryChip(label: 'Belum', value: '${sum['belumLengkap']}',
                  color: const Color(0xFFDC2626)),
              _SummaryChip(label: 'Rata-rata', value: '${sum['rataRata']}',
                  color: const Color(0xFF2563EB)),
            ]),
            const SizedBox(height: 14),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              // Tombol Lihat Riwayat
              if (_riwayatData.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.history, size: 16),
                  label: Text('Lihat Riwayat (${_riwayatData.length} siswa)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              const Spacer(),
              OutlinedButton(onPressed: _handleReset, child: const Text('Reset')),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Tabel nilai siswa
        if (_selectedKelas.isNotEmpty)
          Container(
            decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bdr)),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Daftar Siswa — ${_selectedKelasObj?['nama_kelas'] ?? '-'}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  Text('Isi nilai praktik, sikap, dan laporan untuk setiap siswa.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ]),
              ),
              const Divider(height: 1),

              if (_loadingSiswa)
                const Padding(padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()))
              else if (_siswaList.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Tidak ada siswa di kelas ini.',
                        style: TextStyle(color: Colors.grey[400]))))
              else
                Column(children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _siswaList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final siswa = _siswaList[i];
                      final sid   = siswa['id'].toString();
                      final row   = _nilaiMap[sid] ?? {};
                      final akhir = _hitungNilaiAkhir(row);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            SizedBox(width: 24,
                                child: Text('${i + 1}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(row['nama_siswa'] ?? siswa['nama_lengkap'] ?? siswa['nama_siswa'] ?? '-',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B))),
                              Text(row['nisn'] ?? siswa['nisn'] ?? '-',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(akhir.toStringAsFixed(2),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                                      color: _getPredikatColor(akhir))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: _getPredikatBg(akhir),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(_getPredikat(akhir),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                        color: _getPredikatColor(akhir))),
                              ),
                            ]),
                          ]),
                          const SizedBox(height: 10),

                          Row(children: [
                            _NilaiInput(label: 'Praktik (0-100)',
                                ctrl: _getNilaiCtrl(sid, 'nilai_praktik'), isDark: isDark),
                            const SizedBox(width: 8),
                            _NilaiInput(label: 'Sikap (0-100)',
                                ctrl: _getNilaiCtrl(sid, 'nilai_sikap'), isDark: isDark),
                            const SizedBox(width: 8),
                            _NilaiInput(label: 'Laporan (0-100)',
                                ctrl: _getNilaiCtrl(sid, 'nilai_laporan'), isDark: isDark),
                          ]),
                          const SizedBox(height: 8),

                          TextField(
                            controller: _getCatatanCtrl(sid),
                            style: TextStyle(fontSize: 12,
                                color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Catatan (opsional)',
                              hintStyle: TextStyle(fontSize: 12,
                                  color: isDark ? Colors.white38 : Colors.grey[400]),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF252836) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1))),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                  borderSide: BorderSide(color: Color(0xFF2563EB), width: 2)),
                            ),
                          ),
                        ]),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _handleSimpan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _saving ? 'Menyimpan...' : '💾  Simpan Nilai PKL',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ]),
            ]),
          ),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ── TAB RIWAYAT ───────────────────────────────────────────────────────────

  Widget _buildRiwayatTab(bool isDark, Color card, Color bdr) {
    // Belum ada riwayat
    if (_riwayatData.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('Belum ada riwayat.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey[600])),
          const SizedBox(height: 6),
          Text('Isi nilai di tab Input lalu tekan Simpan.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _tabController.animateTo(0),
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Ke Input Nilai'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      );
    }

    // Kalkulasi rata-rata dari snapshot
    double totalNilaiAkhir = 0;
    int lengkap = 0;
    for (final item in _riwayatData) {
      final bp = (item['bobot_praktik'] ?? _bobotPraktik) as int;
      final bs = (item['bobot_sikap']   ?? _bobotSikap)   as int;
      final bl = (item['bobot_laporan'] ?? _bobotLaporan) as int;
      final p  = double.tryParse(item['nilai_praktik']?.toString() ?? '') ?? 0;
      final s  = double.tryParse(item['nilai_sikap']?.toString()   ?? '') ?? 0;
      final l  = double.tryParse(item['nilai_laporan']?.toString() ?? '') ?? 0;
      final na = (p * bp / 100) + (s * bs / 100) + (l * bl / 100);
      totalNilaiAkhir += na;
      if (p > 0 || s > 0 || l > 0) lengkap++;
    }
    final rataRata = lengkap > 0
        ? (totalNilaiAkhir / lengkap).toStringAsFixed(2)
        : '0';
    final bobot = _riwayatData.first;

    return Column(children: [

      // ── Header info ──────────────────────────────────────────────────────
      Container(
        color: card,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Judul + export
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Riwayat Nilai Tersimpan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B))),
              Text('$_riwayatNamaKelas  •  Disimpan: $_riwayatWaktuSimpan',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ])),
            ElevatedButton.icon(
              onPressed: (_exportingExcel || _riwayatData.isEmpty) ? null : _handleExportExcel,
              icon: _exportingExcel
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download, size: 16),
              label: const Text('Export Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Ringkasan bobot + statistik
          Wrap(spacing: 20, runSpacing: 6, children: [
            _SummaryChip(
              label: 'Bobot',
              value: 'P${bobot['bobot_praktik']}% · '
                     'S${bobot['bobot_sikap']}% · '
                     'L${bobot['bobot_laporan']}%',
              color: const Color(0xFF2563EB),
            ),
            _SummaryChip(
              label: 'Total Siswa',
              value: '${_riwayatData.length}',
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            _SummaryChip(
              label: 'Rata-rata',
              value: rataRata,
              color: _getPredikatColor(double.tryParse(rataRata) ?? 0),
            ),
          ]),
        ]),
      ),
      const Divider(height: 1),

      // ── Daftar siswa ─────────────────────────────────────────────────────
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _riwayatData.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final item    = _riwayatData[i];
            final bp      = (item['bobot_praktik'] ?? _bobotPraktik) as int;
            final bs      = (item['bobot_sikap']   ?? _bobotSikap)   as int;
            final bl      = (item['bobot_laporan'] ?? _bobotLaporan) as int;
            final praktik = double.tryParse(item['nilai_praktik']?.toString() ?? '') ?? 0;
            final sikap   = double.tryParse(item['nilai_sikap']?.toString()   ?? '') ?? 0;
            final laporan = double.tryParse(item['nilai_laporan']?.toString() ?? '') ?? 0;
            final akhir   = (praktik * bp / 100) + (sikap * bs / 100) + (laporan * bl / 100);
            final catatan = item['catatan']?.toString() ?? '';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: bdr)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Nama + nilai akhir + predikat
                Row(children: [
                  // Nomor urut
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                        style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['nama_siswa']?.toString() ?? '-',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E293B))),
                    Text('NISN: ${item['nisn']?.toString() ?? '-'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(akhir.toStringAsFixed(2),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                            color: _getPredikatColor(akhir))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: _getPredikatBg(akhir),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(_getPredikat(akhir),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: _getPredikatColor(akhir))),
                    ),
                  ]),
                ]),
                const SizedBox(height: 12),

                // 3 kotak komponen nilai
                Row(children: [
                  _NilaiChip(label: 'Praktik ($bp%)',
                      value: praktik.toStringAsFixed(1), isDark: isDark),
                  const SizedBox(width: 8),
                  _NilaiChip(label: 'Sikap ($bs%)',
                      value: sikap.toStringAsFixed(1), isDark: isDark),
                  const SizedBox(width: 8),
                  _NilaiChip(label: 'Laporan ($bl%)',
                      value: laporan.toStringAsFixed(1), isDark: isDark),
                ]),

                // Catatan
                if (catatan.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('📝 ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(catatan,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500],
                              fontStyle: FontStyle.italic)),
                    ),
                  ]),
                ],
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Lbl extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Lbl(this.text, this.isDark);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
          color: isDark ? Colors.white38 : Colors.grey[500]));
}

class _Dropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final bool isDark;
  const _Dropdown({required this.value, required this.hint,
      required this.items, required this.onChanged, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          border: Border.all(
              color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value, isExpanded: true,
            hint: Text(hint, style: TextStyle(fontSize: 13,
                color: isDark ? Colors.white38 : Colors.grey[400])),
            dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
            style: TextStyle(fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF1E293B)),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
}

class _BobotField extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isDark;
  final ValueChanged<String> onChanged;
  const _BobotField(
      {required this.ctrl, required this.isDark, required this.onChanged});
  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 13,
            color: isDark ? Colors.white : Colors.black87),
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? const Color(0xFF252836) : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1))),
          focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Color(0xFF2563EB), width: 2)),
        ),
      );
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]);
}

class _NilaiInput extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool isDark;
  const _NilaiInput(
      {required this.label, required this.ctrl, required this.isDark});
  @override
  Widget build(BuildContext context) => Expanded(
        child: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : Colors.grey[400],
                fontWeight: FontWeight.normal),
            filled: true,
            fillColor: isDark ? const Color(0xFF252836) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF3D4155)
                        : const Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF3D4155)
                        : const Color(0xFFCBD5E1))),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF2563EB), width: 2)),
          ),
        ),
      );
}

class _NilaiChip extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _NilaiChip(
      {required this.label, required this.value, required this.isDark});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF252836)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isDark
                    ? const Color(0xFF3D4155)
                    : const Color(0xFFE2E8F0)),
          ),
          child: Column(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color:
                        isDark ? Colors.white : const Color(0xFF1E293B))),
          ]),
        ),
      );
}