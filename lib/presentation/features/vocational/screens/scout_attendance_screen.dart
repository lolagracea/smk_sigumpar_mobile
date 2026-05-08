import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/services/vocational_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/secure_storage.dart';

// ─────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────

const _statusOpts = ['hadir', 'izin', 'sakit', 'alpa'];

const _statusLabel = {
  'hadir': 'Hadir',
  'izin': 'Izin',
  'sakit': 'Sakit',
  'alpa': 'Alpa',
};

const _statusColor = {
  'hadir': Color(0xFF22C55E),
  'izin': Color(0xFFEAB308),
  'sakit': Color(0xFF3B82F6),
  'alpa': Color(0xFFEF4444),
};

const _statusBg = {
  'hadir': Color(0xFFDCFCE7),
  'izin': Color(0xFFFEF9C3),
  'sakit': Color(0xFFDBEAFE),
  'alpa': Color(0xFFFFEBEB),
};

const _statusFg = {
  'hadir': Color(0xFF15803D),
  'izin': Color(0xFFCA8A04),
  'sakit': Color(0xFF1D4ED8),
  'alpa': Color(0xFFB91C1C),
};

enum _Tab { input, riwayat, rekap }

// ─────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────

class ScoutAttendanceScreen extends StatefulWidget {
  const ScoutAttendanceScreen({super.key});

  @override
  State<ScoutAttendanceScreen> createState() => _ScoutAttendanceScreenState();
}

class _ScoutAttendanceScreenState extends State<ScoutAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late final _ScoutAttendanceController _ctrl;
  late final TabController _tabController;
  _Tab _tab = _Tab.input;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final dioClient = DioClient(secureStorage: sl<SecureStorage>());
    _ctrl = _ScoutAttendanceController(
      service: VocationalService(dioClient: dioClient),
    );
    _ctrl.loadKelas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1117) : const Color(0xFFF8F9FC);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1A1D27) : Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Absensi Pramuka',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Kegiatan Kepramukaan',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: _TabBar(
                current: _tab,
                onChanged: (t) => setState(() => _tab = t),
                isDark: isDark,
              ),
            ),
          ),
          body: () {
            switch (_tab) {
              case _Tab.input:
                return _InputTab(ctrl: _ctrl, isDark: isDark);
              case _Tab.riwayat:
                return _RiwayatTab(ctrl: _ctrl, isDark: isDark);
              case _Tab.rekap:
                return _RekapTab(ctrl: _ctrl, isDark: isDark);
            }
          }(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final _Tab current;
  final ValueChanged<_Tab> onChanged;
  final bool isDark;

  const _TabBar({required this.current, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      (_Tab.input, '✏️', 'Absensi'),
      (_Tab.riwayat, '📋', 'Riwayat'),
      (_Tab.rekap, '📊', 'Rekap'),
    ];

    return Container(
      color: isDark ? const Color(0xFF1A1D27) : Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: items.map((item) {
          final (tab, icon, label) = item;
          final active = current == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF2563EB)
                      : (isDark ? const Color(0xFF252836) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : (isDark ? Colors.white60 : Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────

class _ScoutAttendanceController extends ChangeNotifier {
  final VocationalService service;

  _ScoutAttendanceController({required this.service});

  List<Map<String, dynamic>> kelasList = [];
  String selectedKelasId = '';
  String tanggal = _todayStr();
  String deskripsi = '';
  List<Map<String, dynamic>> siswaList = [];
  Map<String, Map<String, String>> absensi = {};
  bool loadingSiswa = false;
  bool saving = false;

  String riwayatKelasId = '';
  String riwayatTanggal = '';
  List<Map<String, dynamic>> riwayatData = [];
  bool loadingRiwayat = false;

  String rekapKelasId = '';
  String rekapMulai = '';
  String rekapAkhir = '';
  List<Map<String, dynamic>> rekapSiswa = [];
  List<Map<String, dynamic>> rekapData = [];
  bool loadingRekap = false;

  String? errorMessage;

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String getNamaKelas(dynamic kelasId) {
    final k = kelasList.firstWhere(
      (e) => e['id'].toString() == kelasId.toString(),
      orElse: () => {},
    );
    return k['nama_kelas'] ?? '-';
  }

  Map<String, dynamic> get selectedKelasObj =>
      kelasList.firstWhere((e) => e['id'].toString() == selectedKelasId, orElse: () => {});

  Map<String, dynamic> get rekapKelasObj =>
      kelasList.firstWhere((e) => e['id'].toString() == rekapKelasId, orElse: () => {});

  Map<String, dynamic> get summary {
    final data = {'hadir': 0, 'izin': 0, 'sakit': 0, 'alpa': 0, 'belum': 0, 'total': siswaList.length};
    for (final siswa in siswaList) {
      final status = absensi[siswa['id'].toString()]?['status'] ?? '';
      if (_statusOpts.contains(status)) {
        data[status] = (data[status] ?? 0) + 1;
      } else {
        data['belum'] = (data['belum'] ?? 0) + 1;
      }
    }
    return data;
  }

  Future<void> loadKelas() async {
    try {
      final res = await service.getRawKelasVokasi();
      kelasList = List<Map<String, dynamic>>.from(res['data'] ?? []);
    } catch (e) {
      errorMessage = 'Gagal memuat daftar kelas';
    }
    notifyListeners();
  }

  Future<void> loadSiswaByKelas(String kelasId) async {
    if (kelasId.isEmpty) {
      siswaList = [];
      absensi = {};
      notifyListeners();
      return;
    }
    loadingSiswa = true;
    notifyListeners();
    try {
      final res = await service.getRawSiswaVokasi(kelasId: kelasId);
      siswaList = List<Map<String, dynamic>>.from(res['data'] ?? []);
      absensi = {for (final s in siswaList) s['id'].toString(): {'status': '', 'keterangan': ''}};
    } catch (_) {
      siswaList = [];
      absensi = {};
    }
    loadingSiswa = false;
    notifyListeners();
  }

  void setStatus(String siswaId, String status) {
    absensi[siswaId] = {...?absensi[siswaId], 'status': status};
    notifyListeners();
  }

  void setKeterangan(String siswaId, String ket) {
    absensi[siswaId] = {...?absensi[siswaId], 'keterangan': ket};
    notifyListeners();
  }

  void tandaiSemua(String status) {
    for (final siswa in siswaList) {
      final id = siswa['id'].toString();
      absensi[id] = {...?absensi[id], 'status': status};
    }
    notifyListeners();
  }

  Future<String?> simpanAbsensi() async {
    if (selectedKelasId.isEmpty) return 'Pilih kelas terlebih dahulu';
    if (siswaList.isEmpty) return 'Tidak ada siswa di kelas ini';
    final belum = siswaList.where((s) => (absensi[s['id'].toString()]?['status'] ?? '').isEmpty);
    if (belum.isNotEmpty) return 'Semua siswa harus diberi status absensi';

    saving = true;
    notifyListeners();

    final payload = {
      'kelas_id': selectedKelasId,
      'tanggal': tanggal,
      'deskripsi': deskripsi,
      'data_absensi': siswaList.map((s) => {
        'siswa_id': s['id'],
        'nama_lengkap': s['nama_lengkap'] ?? s['nama_siswa'] ?? '-',
        'nisn': s['nisn'],
        'status': absensi[s['id'].toString()]?['status'] ?? '',
        'keterangan': absensi[s['id'].toString()]?['keterangan'] ?? '',
      }).toList(),
    };

    try {
      await service.submitAbsensiPramuka(payload);
      riwayatKelasId = selectedKelasId;
      riwayatTanggal = tanggal;
      rekapKelasId = selectedKelasId;
      rekapMulai = tanggal;
      rekapAkhir = tanggal;
      deskripsi = '';
      await loadRiwayat();
      await loadRekap();
    } catch (e) {
      saving = false;
      notifyListeners();
      return 'Gagal menyimpan absensi';
    }

    saving = false;
    notifyListeners();
    return null;
  }

  Future<void> loadRiwayat() async {
    loadingRiwayat = true;
    notifyListeners();
    try {
      final res = await service.getRawAbsensiPramuka(
        kelasId: riwayatKelasId.isEmpty ? null : riwayatKelasId,
        tanggal: riwayatTanggal.isEmpty ? null : riwayatTanggal,
      );
      riwayatData = List<Map<String, dynamic>>.from(res['data'] ?? []);
    } catch (_) {
      riwayatData = [];
    }
    loadingRiwayat = false;
    notifyListeners();
  }

  Future<String?> loadRekap() async {
    if (rekapKelasId.isEmpty) return 'Pilih kelas terlebih dahulu';
    loadingRekap = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        service.getRawSiswaVokasi(kelasId: rekapKelasId),
        service.getRawRekapAbsensiPramuka(
          kelasId: rekapKelasId,
          tanggalMulai: rekapMulai.isEmpty ? null : rekapMulai,
          tanggalAkhir: rekapAkhir.isEmpty ? null : rekapAkhir,
        ),
      ]);
      rekapSiswa = List<Map<String, dynamic>>.from(results[0]['data'] ?? []);
      rekapData = List<Map<String, dynamic>>.from(results[1]['data'] ?? []);
    } catch (_) {
      rekapSiswa = [];
      rekapData = [];
    }
    loadingRekap = false;
    notifyListeners();
    return null;
  }

  Map<String, dynamic> getRekapBySiswa(dynamic siswaId) {
    return rekapData.firstWhere(
      (e) => e['siswa_id'].toString() == siswaId.toString(),
      orElse: () => {'hadir': 0, 'izin': 0, 'sakit': 0, 'alpa': 0, 'total': 0},
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB: INPUT ABSENSI
// ─────────────────────────────────────────────────────────

class _InputTab extends StatefulWidget {
  final _ScoutAttendanceController ctrl;
  final bool isDark;
  const _InputTab({required this.ctrl, required this.isDark});

  @override
  State<_InputTab> createState() => _InputTabState();
}

class _InputTabState extends State<_InputTab> {
  final _deskripsiCtrl = TextEditingController();

  @override
  void dispose() {
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final isDark = widget.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _Card(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Kelas', isDark: isDark),
                const SizedBox(height: 6),
                _DropdownKelas(
                  value: ctrl.selectedKelasId.isEmpty ? null : ctrl.selectedKelasId,
                  items: ctrl.kelasList,
                  isDark: isDark,
                  onChanged: (val) {
                    ctrl.selectedKelasId = val ?? '';
                    ctrl.loadSiswaByKelas(ctrl.selectedKelasId);
                  },
                ),
                const SizedBox(height: 12),
                _Label('Tanggal Kegiatan', isDark: isDark),
                const SizedBox(height: 6),
                _DateField(
                  value: ctrl.tanggal,
                  isDark: isDark,
                  onChanged: (v) { ctrl.tanggal = v; ctrl.notifyListeners(); },
                ),
                const SizedBox(height: 12),
                _Label('Deskripsi Kegiatan', isDark: isDark),
                const SizedBox(height: 6),
                TextField(
                  controller: _deskripsiCtrl,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                  decoration: _inputDeco('Contoh: Baris-berbaris, P3K...', isDark),
                  onChanged: (v) => ctrl.deskripsi = v,
                ),
              ],
            ),
          ),

          if (ctrl.selectedKelasId.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SummaryRow(summary: ctrl.summary, isDark: isDark),
            const SizedBox(height: 12),
            _Card(
              isDark: isDark,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daftar Siswa — ${ctrl.selectedKelasObj['nama_kelas'] ?? '-'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              ctrl.tanggal,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _statusOpts.map((s) {
                      return GestureDetector(
                        onTap: () => ctrl.tandaiSemua(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor[s],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Semua ${_statusLabel[s]}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  const SizedBox(height: 4),
                  if (ctrl.loadingSiswa)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (ctrl.siswaList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('Tidak ada siswa di kelas ini.', style: TextStyle(color: Colors.grey[400])),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ctrl.siswaList.length,
                      separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white12 : const Color(0xFFF1F5F9), height: 1),
                      itemBuilder: (context, i) {
                        final siswa = ctrl.siswaList[i];
                        final id = siswa['id'].toString();
                        final st = ctrl.absensi[id]?['status'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF252836) : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : Colors.grey[600]),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          siswa['nama_lengkap'] ?? siswa['nama_siswa'] ?? '-',
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                        ),
                                        Text(
                                          'NISN: ${siswa['nisn'] ?? '-'}',
                                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: _statusOpts.map((status) {
                                  final active = st == status;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => ctrl.setStatus(id, status),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        decoration: BoxDecoration(
                                          color: active ? _statusColor[status] : (isDark ? const Color(0xFF252836) : const Color(0xFFF1F5F9)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _statusLabel[status]!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: active ? Colors.white : (isDark ? Colors.white38 : Colors.grey[500]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                                decoration: _inputDeco('Keterangan (opsional)', isDark),
                                onChanged: (v) => ctrl.setKeterangan(id, v),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  if (ctrl.siswaList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: ctrl.saving
                            ? null
                            : () async {
                                final err = await ctrl.simpanAbsensi();
                                if (!context.mounted) return;
                                if (err != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(err), backgroundColor: Colors.red),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Absensi pramuka berhasil disimpan'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          ctrl.saving ? 'Menyimpan...' : '💾  Simpan Absensi',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB: RIWAYAT
// ─────────────────────────────────────────────────────────

class _RiwayatTab extends StatelessWidget {
  final _ScoutAttendanceController ctrl;
  final bool isDark;
  const _RiwayatTab({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _Card(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Riwayat Absensi',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            _Label('Kelas', isDark: isDark),
            const SizedBox(height: 6),
            _DropdownKelas(
              value: ctrl.riwayatKelasId.isEmpty ? null : ctrl.riwayatKelasId,
              items: ctrl.kelasList,
              isDark: isDark,
              hintText: 'Semua Kelas',
              onChanged: (v) { ctrl.riwayatKelasId = v ?? ''; ctrl.notifyListeners(); },
            ),
            const SizedBox(height: 12),
            _Label('Tanggal', isDark: isDark),
            const SizedBox(height: 6),
            _DateField(
              value: ctrl.riwayatTanggal,
              isDark: isDark,
              hintText: 'Pilih tanggal...',
              onChanged: (v) { ctrl.riwayatTanggal = v; ctrl.notifyListeners(); },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ctrl.loadingRiwayat ? null : () => ctrl.loadRiwayat(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(ctrl.loadingRiwayat ? 'Memuat...' : '🔍  Tampilkan',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
            if (ctrl.loadingRiwayat)
              const Center(child: CircularProgressIndicator())
            else if (ctrl.riwayatData.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Klik Tampilkan untuk melihat riwayat absensi.',
                    style: TextStyle(color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ctrl.riwayatData.length,
                separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white12 : const Color(0xFFF1F5F9), height: 1),
                itemBuilder: (context, i) {
                  final item = ctrl.riwayatData[i];
                  final st = item['status']?.toString() ?? '-';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['nama_lengkap'] ?? '-',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item['tanggal']?.toString().substring(0, 10) ?? '-'} · ${ctrl.getNamaKelas(item['kelas_id'])}',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500]),
                              ),
                              if ((item['keterangan'] ?? '').toString().isNotEmpty)
                                Text(
                                  item['keterangan'].toString(),
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500]),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusBg[st] ?? const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel[st] ?? st,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _statusFg[st] ?? Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB: REKAP
// ─────────────────────────────────────────────────────────

class _RekapTab extends StatelessWidget {
  final _ScoutAttendanceController ctrl;
  final bool isDark;
  const _RekapTab({required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _Card(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rekap Absensi Pramuka',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            _Label('Kelas', isDark: isDark),
            const SizedBox(height: 6),
            _DropdownKelas(
              value: ctrl.rekapKelasId.isEmpty ? null : ctrl.rekapKelasId,
              items: ctrl.kelasList,
              isDark: isDark,
              onChanged: (v) { ctrl.rekapKelasId = v ?? ''; ctrl.notifyListeners(); },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Tanggal Mulai', isDark: isDark),
                      const SizedBox(height: 6),
                      _DateField(
                        value: ctrl.rekapMulai,
                        isDark: isDark,
                        hintText: 'Mulai...',
                        onChanged: (v) { ctrl.rekapMulai = v; ctrl.notifyListeners(); },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Tanggal Akhir', isDark: isDark),
                      const SizedBox(height: 6),
                      _DateField(
                        value: ctrl.rekapAkhir,
                        isDark: isDark,
                        hintText: 'Akhir...',
                        onChanged: (v) { ctrl.rekapAkhir = v; ctrl.notifyListeners(); },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ctrl.loadingRekap
                    ? null
                    : () async {
                        final err = await ctrl.loadRekap();
                        if (!context.mounted) return;
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: Colors.red),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(ctrl.loadingRekap ? 'Memuat...' : '🔍  Tampilkan',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
            if (ctrl.loadingRekap)
              const Center(child: CircularProgressIndicator())
            else if (ctrl.rekapSiswa.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('Pilih kelas lalu klik Tampilkan untuk melihat rekap.',
                      style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252836) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 28),
                    Expanded(flex: 3, child: Text('Nama', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.grey[600]))),
                    ...[('H', 'hadir'), ('I', 'izin'), ('S', 'sakit'), ('A', 'alpa'), ('∑', null)].map((e) {
                      final (label, _) = e;
                      return SizedBox(
                        width: 36,
                        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.grey[600])),
                      );
                    }),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ctrl.rekapSiswa.length,
                separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white12 : const Color(0xFFF1F5F9), height: 1),
                itemBuilder: (context, i) {
                  final siswa = ctrl.rekapSiswa[i];
                  final data = ctrl.getRekapBySiswa(siswa['id']);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 28, child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[400]))),
                        Expanded(
                          flex: 3,
                          child: Text(
                            siswa['nama_lengkap'] ?? siswa['nama_siswa'] ?? '-',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 36, child: Text('${data['hadir'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)))),
                        SizedBox(width: 36, child: Text('${data['izin'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFCA8A04)))),
                        SizedBox(width: 36, child: Text('${data['sakit'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)))),
                        SizedBox(width: 36, child: Text('${data['alpa'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)))),
                        SizedBox(width: 36, child: Text('${data['total'] ?? 0}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B)))),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final Map<String, dynamic> summary;
  final bool isDark;
  const _SummaryRow({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total', '${summary['total']}', isDark ? const Color(0xFF252836) : Colors.white, isDark ? Colors.white : const Color(0xFF1E293B)),
      ('Belum', '${summary['belum']}', isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB), isDark ? Colors.white70 : const Color(0xFF6B7280)),
      ('Hadir', '${summary['hadir']}', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      ('Izin', '${summary['izin']}', const Color(0xFFFEF9C3), const Color(0xFFCA8A04)),
      ('Sakit', '${summary['sakit']}', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      ('Alpa', '${summary['alpa']}', const Color(0xFFFFEBEB), const Color(0xFFB91C1C)),
    ];

    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items.map((item) {
          final (label, value, bg, fg) = item;
          return Container(
            width: 72,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fg.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg.withOpacity(0.7))),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: fg)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D27) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2D3142) : const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? Colors.white38 : Colors.grey[500],
      ),
    );
  }
}

class _DropdownKelas extends StatelessWidget {
  final String? value;
  final List<Map<String, dynamic>> items;
  final bool isDark;
  final String hintText;
  final ValueChanged<String?> onChanged;

  const _DropdownKelas({
    required this.value,
    required this.items,
    required this.isDark,
    required this.onChanged,
    this.hintText = '-- Pilih Kelas --',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hintText, style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[400])),
          dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B)),
          items: [
            if (hintText != '-- Pilih Kelas --')
              DropdownMenuItem(value: null, child: Text(hintText, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400]))),
            ...items.map((k) => DropdownMenuItem(value: k['id'].toString(), child: Text(k['nama_kelas'] ?? '-'))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String value;
  final bool isDark;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _DateField({
    required this.value,
    required this.isDark,
    required this.onChanged,
    this.hintText = '',
  });

  String _format(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value.isEmpty ? DateTime.now() : DateTime.tryParse(value) ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(_format(picked));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          border: Border.all(color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? Colors.white38 : Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              value.isEmpty ? hintText : value,
              style: TextStyle(
                fontSize: 13,
                color: value.isEmpty ? (isDark ? Colors.white38 : Colors.grey[400]) : (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDeco(String hint, bool isDark) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[400]),
      filled: true,
      fillColor: isDark ? const Color(0xFF252836) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF3D4155) : const Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
    );
