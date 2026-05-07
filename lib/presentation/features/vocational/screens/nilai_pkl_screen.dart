import 'package:flutter/material.dart';
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

class _NilaiPKLScreenState extends State<NilaiPKLScreen> {
  late final DioClient _dio;

  List<Map<String, dynamic>> _kelasList = [];
  String _selectedKelas = '';

  List<Map<String, dynamic>> _siswaList = [];
  // nilaiMap: siswa_id → { nilai_praktik, nilai_sikap, nilai_laporan, catatan, nama_siswa, nisn }
  Map<String, Map<String, dynamic>> _nilaiMap = {};

  // Bobot
  int _bobotPraktik = 50;
  int _bobotSikap   = 30;
  int _bobotLaporan = 20;

  bool _loadingKelas = false;
  bool _loadingSiswa = false;
  bool _saving       = false;

  // Controllers untuk bobot
  late TextEditingController _bobotPraktikCtrl;
  late TextEditingController _bobotSikapCtrl;
  late TextEditingController _bobotLaporanCtrl;

  Map<String, dynamic>? get _selectedKelasObj => _kelasList
      .where((k) => k['id'].toString() == _selectedKelas)
      .isNotEmpty
      ? _kelasList.firstWhere((k) => k['id'].toString() == _selectedKelas)
      : null;

  int get _totalBobot => _bobotPraktik + _bobotSikap + _bobotLaporan;

  double _hitungNilaiAkhir(Map<String, dynamic> row) {
    final praktik = double.tryParse(row['nilai_praktik']?.toString() ?? '') ?? 0;
    final sikap   = double.tryParse(row['nilai_sikap']?.toString() ?? '') ?? 0;
    final laporan = double.tryParse(row['nilai_laporan']?.toString() ?? '') ?? 0;
    return (praktik * (_bobotPraktik / 100)) +
        (sikap * (_bobotSikap / 100)) +
        (laporan * (_bobotLaporan / 100));
  }

  // Summary stats
  Map<String, dynamic> get _summary {
    int sudahLengkap = 0;
    int belumLengkap = 0;
    double totalNilai = 0;

    for (final siswa in _siswaList) {
      final row = _nilaiMap[siswa['id'].toString()] ?? {};
      final praktik = row['nilai_praktik']?.toString() ?? '';
      final sikap   = row['nilai_sikap']?.toString() ?? '';
      final laporan = row['nilai_laporan']?.toString() ?? '';
      final lengkap = praktik.isNotEmpty && sikap.isNotEmpty && laporan.isNotEmpty;
      if (lengkap) {
        sudahLengkap++;
        totalNilai += _hitungNilaiAkhir(row);
      } else {
        belumLengkap++;
      }
    }

    final rataRata = sudahLengkap > 0
        ? double.parse((totalNilai / sudahLengkap).toStringAsFixed(2))
        : 0.0;

    return {
      'totalSiswa': _siswaList.length,
      'sudahLengkap': sudahLengkap,
      'belumLengkap': belumLengkap,
      'rataRata': rataRata,
    };
  }

  @override
  void initState() {
    super.initState();
    _dio = DioClient(secureStorage: sl<SecureStorage>());
    _bobotPraktikCtrl = TextEditingController(text: '50');
    _bobotSikapCtrl   = TextEditingController(text: '30');
    _bobotLaporanCtrl = TextEditingController(text: '20');
    _loadKelas();
  }

  @override
  void dispose() {
    _bobotPraktikCtrl.dispose();
    _bobotSikapCtrl.dispose();
    _bobotLaporanCtrl.dispose();
    // Dispose semua controller nilai
    for (final entry in _nilaiControllers.entries) {
      for (final ctrl in entry.value.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  // ─── Controllers nilai per-siswa ─────────────────────────────────────────
  // Map<siswaId, Map<field, TextEditingController>>
  final Map<String, Map<String, TextEditingController>> _nilaiControllers = {};

  TextEditingController _getNilaiCtrl(String siswaId, String field) {
    _nilaiControllers[siswaId] ??= {};
    if (!_nilaiControllers[siswaId]!.containsKey(field)) {
      final initial = _nilaiMap[siswaId]?[field]?.toString() ?? '';
      final ctrl = TextEditingController(text: initial);
      ctrl.addListener(() {
        _updateNilai(siswaId, field, ctrl.text);
      });
      _nilaiControllers[siswaId]![field] = ctrl;
    }
    return _nilaiControllers[siswaId]![field]!;
  }

  TextEditingController _getCatatanCtrl(String siswaId) {
    return _getNilaiCtrl(siswaId, 'catatan');
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

      final siswa =
          List<Map<String, dynamic>>.from(results[0].data['data'] ?? []);
      final nilai =
          List<Map<String, dynamic>>.from(results[1].data['data'] ?? []);

      // Build nilai by siswa_id
      final Map<String, Map<String, dynamic>> nilaiBySiswa = {};
      for (final n in nilai) {
        nilaiBySiswa[n['siswa_id'].toString()] = n;
      }

      // Build nilaiMap
      final Map<String, Map<String, dynamic>> nextMap = {};
      for (final s in siswa) {
        final sid = s['id'].toString();
        final existing = nilaiBySiswa[sid];
        nextMap[sid] = {
          'siswa_id': s['id'],
          'nama_siswa':
              s['nama_lengkap'] ?? s['nama_siswa'] ?? '-',
          'nisn': s['nisn'] ?? '',
          'nilai_praktik': existing?['nilai_praktik']?.toString() ?? '',
          'nilai_sikap':   existing?['nilai_sikap']?.toString() ?? '',
          'nilai_laporan': existing?['nilai_laporan']?.toString() ?? '',
          'catatan':       existing?['catatan'] ?? '',
        };
      }

      // Dispose dan rebuild controllers
      for (final entry in _nilaiControllers.entries) {
        for (final ctrl in entry.value.values) {
          ctrl.dispose();
        }
      }
      _nilaiControllers.clear();

      setState(() {
        _siswaList = siswa;
        _nilaiMap  = nextMap;
      });

      // Init controllers dengan nilai awal
      for (final s in siswa) {
        final sid = s['id'].toString();
        for (final field in ['nilai_praktik', 'nilai_sikap', 'nilai_laporan', 'catatan']) {
          final ctrl = TextEditingController(
              text: nextMap[sid]?[field]?.toString() ?? '');
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
      _nilaiMap[siswaId] = {
        ...(_nilaiMap[siswaId] ?? {}),
        field: value,
      };
    });
  }

  bool _validateNilai() {
    if (_selectedKelas.isEmpty) {
      _snack('Pilih kelas terlebih dahulu', isError: true);
      return false;
    }
    if (_siswaList.isEmpty) {
      _snack('Tidak ada siswa di kelas ini', isError: true);
      return false;
    }
    if (_totalBobot != 100) {
      _snack('Total bobot harus 100%', isError: true);
      return false;
    }
    for (final siswa in _siswaList) {
      final sid = siswa['id'].toString();
      final row = _nilaiMap[sid] ?? {};
      final nama = row['nama_siswa'] ?? siswa['nama_lengkap'] ?? 'siswa';
      for (final field in ['nilai_praktik', 'nilai_sikap', 'nilai_laporan']) {
        final val = row[field]?.toString() ?? '';
        if (val.isEmpty) {
          _snack('Nilai $nama belum lengkap', isError: true);
          return false;
        }
        final n = double.tryParse(val);
        if (n == null || n < 0 || n > 100) {
          _snack('Semua nilai harus angka antara 0 sampai 100', isError: true);
          return false;
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
        'sikap': _bobotSikap,
        'laporan': _bobotLaporan,
      },
      'data_nilai': _siswaList.map((siswa) {
        final sid = siswa['id'].toString();
        final row = _nilaiMap[sid] ?? {};
        return {
          'siswa_id': siswa['id'],
          'nama_siswa': row['nama_siswa'] ?? '',
          'nisn': row['nisn'] ?? '',
          'nilai_praktik': double.tryParse(row['nilai_praktik']?.toString() ?? '') ?? 0,
          'nilai_sikap':   double.tryParse(row['nilai_sikap']?.toString() ?? '') ?? 0,
          'nilai_laporan': double.tryParse(row['nilai_laporan']?.toString() ?? '') ?? 0,
          'catatan': row['catatan'] ?? '',
        };
      }).toList(),
    };

    setState(() => _saving = true);
    try {
      await _dio.post(ApiEndpoints.pklGrades, data: payload);
      _snack('Nilai PKL berhasil disimpan');
      await _loadSiswaDanNilai(_selectedKelas);
    } catch (_) {
      _snack('Gagal menyimpan nilai PKL', isError: true);
    }
    setState(() => _saving = false);
  }

  void _handleReset() {
    setState(() {
      _bobotPraktik = 50;
      _bobotSikap   = 30;
      _bobotLaporan = 20;
      _bobotPraktikCtrl.text = '50';
      _bobotSikapCtrl.text   = '30';
      _bobotLaporanCtrl.text = '20';
    });
    _loadSiswaDanNilai(_selectedKelas);
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
    final sum  = _summary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Input Nilai PKL',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B))),
          Text('Input nilai praktik, sikap, dan laporan PKL berdasarkan kelas',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey[500])),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── Header Card: Kelas + Bobot + Summary ────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bdr)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris: Kelas | Bobot Praktik | Bobot Sikap | Bobot Laporan
                Row(children: [
                  // Kelas
                  Expanded(flex: 2, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Lbl('Kelas', isDark),
                      const SizedBox(height: 6),
                      _Dropdown(
                        value: _selectedKelas.isEmpty ? null : _selectedKelas,
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
                          setState(() => _selectedKelas = v ?? '');
                          _loadSiswaDanNilai(_selectedKelas);
                        },
                        isDark: isDark,
                      ),
                    ],
                  )),
                  const SizedBox(width: 10),

                  // Bobot Praktik
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Lbl('Bobot Praktik', isDark),
                      const SizedBox(height: 6),
                      _BobotField(
                        ctrl: _bobotPraktikCtrl,
                        isDark: isDark,
                        onChanged: (v) =>
                            setState(() => _bobotPraktik = int.tryParse(v) ?? 0),
                      ),
                    ],
                  )),
                  const SizedBox(width: 10),

                  // Bobot Sikap
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Lbl('Bobot Sikap', isDark),
                      const SizedBox(height: 6),
                      _BobotField(
                        ctrl: _bobotSikapCtrl,
                        isDark: isDark,
                        onChanged: (v) =>
                            setState(() => _bobotSikap = int.tryParse(v) ?? 0),
                      ),
                    ],
                  )),
                  const SizedBox(width: 10),

                  // Bobot Laporan
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Lbl('Bobot Laporan', isDark),
                      const SizedBox(height: 6),
                      _BobotField(
                        ctrl: _bobotLaporanCtrl,
                        isDark: isDark,
                        onChanged: (v) =>
                            setState(() => _bobotLaporan = int.tryParse(v) ?? 0),
                      ),
                    ],
                  )),
                ]),
                const SizedBox(height: 14),

                // Summary Row
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _SummaryChip(
                      label: 'Total Bobot',
                      value: '$_totalBobot%',
                      color: _totalBobot == 100
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                    _SummaryChip(
                        label: 'Total Siswa',
                        value: '${sum['totalSiswa']}',
                        color: isDark ? Colors.white70 : Colors.black87),
                    _SummaryChip(
                        label: 'Lengkap',
                        value: '${sum['sudahLengkap']}',
                        color: const Color(0xFF16A34A)),
                    _SummaryChip(
                        label: 'Belum Lengkap',
                        value: '${sum['belumLengkap']}',
                        color: const Color(0xFFDC2626)),
                    _SummaryChip(
                        label: 'Rata-rata',
                        value: '${sum['rataRata']}',
                        color: const Color(0xFF2563EB)),
                  ],
                ),
                const SizedBox(height: 14),

                // Tombol Reset
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton(
                    onPressed: _handleReset,
                    child: const Text('Reset'),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Tabel Nilai ─────────────────────────────────────────
          if (_selectedKelas.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: bdr)),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Daftar Siswa — ${_selectedKelasObj?['nama_kelas'] ?? '-'}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B))),
                      Text(
                          'Isi nilai praktik, sikap, dan laporan untuk setiap siswa.',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                ),
                const Divider(height: 1),

                if (_loadingSiswa)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child:
                          Center(child: CircularProgressIndicator()))
                else if (_siswaList.isEmpty)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                          child: Text(
                              'Tidak ada siswa di kelas ini.',
                              style:
                                  TextStyle(color: Colors.grey[400]))))
                else
                  Column(children: [
                    // Header tabel
                    Container(
                      color: isDark
                          ? const Color(0xFF252836)
                          : const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(children: [
                        _TblHead('No', flex: 1, isDark: isDark),
                        _TblHead('Nama Siswa', flex: 3, isDark: isDark),
                        _TblHead('NISN', flex: 2, isDark: isDark),
                        _TblHead('Praktik', flex: 2, isDark: isDark, center: true),
                        _TblHead('Sikap', flex: 2, isDark: isDark, center: true),
                        _TblHead('Laporan', flex: 2, isDark: isDark, center: true),
                        _TblHead('Akhir', flex: 2, isDark: isDark, center: true),
                        _TblHead('Predikat', flex: 3, isDark: isDark, center: true),
                      ]),
                    ),
                    const Divider(height: 1),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _siswaList.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final siswa = _siswaList[i];
                        final sid = siswa['id'].toString();
                        final row = _nilaiMap[sid] ?? {};
                        final akhir = _hitungNilaiAkhir(row);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nama + NISN
                              Row(children: [
                                SizedBox(
                                    width: 24,
                                    child: Text('${i + 1}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500]))),
                                Expanded(child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row['nama_siswa'] ??
                                          siswa['nama_lengkap'] ??
                                          siswa['nama_siswa'] ??
                                          '-',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1E293B)),
                                    ),
                                    Text(
                                      row['nisn'] ?? siswa['nisn'] ?? '-',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[400]),
                                    ),
                                  ],
                                )),
                                // Nilai Akhir + Predikat
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        akhir.toStringAsFixed(2),
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                _getPredikatColor(akhir)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getPredikatBg(akhir),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _getPredikat(akhir),
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  _getPredikatColor(akhir)),
                                        ),
                                      ),
                                    ]),
                              ]),
                              const SizedBox(height: 10),

                              // Input nilai 3 kolom
                              Row(children: [
                                _NilaiInput(
                                  label: 'Praktik (0-100)',
                                  ctrl: _getNilaiCtrl(sid, 'nilai_praktik'),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _NilaiInput(
                                  label: 'Sikap (0-100)',
                                  ctrl: _getNilaiCtrl(sid, 'nilai_sikap'),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _NilaiInput(
                                  label: 'Laporan (0-100)',
                                  ctrl: _getNilaiCtrl(sid, 'nilai_laporan'),
                                  isDark: isDark,
                                ),
                              ]),
                              const SizedBox(height: 8),

                              // Catatan
                              TextField(
                                controller: _getCatatanCtrl(sid),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Catatan (opsional)',
                                  hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey[400]),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF252836)
                                      : Colors.white,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF3D4155)
                                              : const Color(0xFFCBD5E1))),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF3D4155)
                                              : const Color(0xFFCBD5E1))),
                                  focusedBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(8)),
                                      borderSide: BorderSide(
                                          color: Color(0xFF2563EB),
                                          width: 2)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Tombol Simpan
                    if (_siswaList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _handleSimpan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _saving
                                  ? 'Menyimpan...'
                                  : '💾  Simpan Nilai PKL',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                  ]),
              ]),
            ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
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
            value: value, isExpanded: true,
            hint: Text(hint,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.grey[400])),
            dropdownColor:
                isDark ? const Color(0xFF252836) : Colors.white,
            style: TextStyle(
                fontSize: 13,
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
      {required this.ctrl,
      required this.isDark,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black87),
        onChanged: onChanged,
        decoration: InputDecoration(
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

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500])),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
      ]);
}

class _TblHead extends StatelessWidget {
  final String text;
  final int flex;
  final bool isDark;
  final bool center;
  const _TblHead(this.text,
      {required this.flex, required this.isDark, this.center = false});
  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text.toUpperCase(),
            textAlign: center ? TextAlign.center : TextAlign.left,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? Colors.white38 : Colors.grey[500])),
      );
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF3D4155)
                        : const Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF3D4155)
                        : const Color(0xFFCBD5E1))),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide:
                    BorderSide(color: Color(0xFF2563EB), width: 2)),
          ),
        ),
      );
}