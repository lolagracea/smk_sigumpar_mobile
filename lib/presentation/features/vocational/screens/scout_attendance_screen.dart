import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../data/models/absensi_pramuka_model.dart';
import '../providers/vocational_provider.dart';
import '../widgets/pramuka_drawer.dart';

// ─────────────────────────────────────────────────────────────
// Konstanta status — mirror web STATUS_OPTS, STATUS_LABEL, dll.
// ─────────────────────────────────────────────────────────────
const _statusOpts = ['hadir', 'izin', 'sakit', 'alpa'];

const _statusLabel = {
  'hadir': 'Hadir',
  'izin': 'Izin',
  'sakit': 'Sakit',
  'alpa': 'Alpa',
};

const _statusColor = {
  'hadir': Color(0xFF2E7D32),
  'izin': Color(0xFFF57F17),
  'sakit': Color(0xFF1565C0),
  'alpa': Color(0xFFC62828),
};

const _statusBgColor = {
  'hadir': Color(0xFFE8F5E9),
  'izin': Color(0xFFFFF8E1),
  'sakit': Color(0xFFE3F2FD),
  'alpa': Color(0xFFFFEBEE),
};

// ─────────────────────────────────────────────────────────────
// Tab definitions — mirror web TABS
// ─────────────────────────────────────────────────────────────
enum _Tab { input, riwayat, rekap }

const _tabData = [
  (tab: _Tab.input, label: 'Absensi', icon: Icons.edit_rounded),
  (tab: _Tab.riwayat, label: 'Riwayat', icon: Icons.list_alt_rounded),
  (tab: _Tab.rekap, label: 'Rekap', icon: Icons.bar_chart_rounded),
];

class ScoutAttendanceScreen extends StatefulWidget {
  const ScoutAttendanceScreen({super.key});

  @override
  State<ScoutAttendanceScreen> createState() => _ScoutAttendanceScreenState();
}

class _ScoutAttendanceScreenState extends State<ScoutAttendanceScreen> {
  _Tab _currentTab = _Tab.input;

  // ── Tab Input state ──────────────────────────────────────────
  String _selectedKelasId = '';
  String _tanggal = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final _deskripsiCtrl = TextEditingController();

  // ── Tab Riwayat state ────────────────────────────────────────
  String _riwayatKelasId = '';
  String _riwayatTanggal = '';

  // ── Tab Rekap state ──────────────────────────────────────────
  String _rekapKelasId = '';
  String _rekapMulai = '';
  String _rekapAkhir = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocationalProvider>().loadKelasVokasional();
    });
  }

  @override
  void dispose() {
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      drawer: const PramukaDrawer(currentRoute: RouteNames.scoutAttendance),
      body: Column(
        children: [
          // Header + Tab bar — mirror web bg-white border-b + tabs
          _buildHeaderAndTabs(),
          // Tab content
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Absensi Pramuka'),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Header + Tabs — mirror web header section with TABS
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeaderAndTabs() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + subtitle — mirror web h1 + p
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Absensi Pramuka',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Absensi siswa kegiatan pramuka.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Tab buttons — mirror web flex gap-2
          Row(
            children: _tabData.map((t) {
              final isActive = _currentTab == t.tab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _currentTab = t.tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          t.icon,
                          size: 16,
                          color: isActive ? AppColors.white : AppColors.grey600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? AppColors.white : AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 1),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Tab Content Router
  // ─────────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_currentTab) {
      case _Tab.input:
        return _buildTabInput();
      case _Tab.riwayat:
        return _buildTabRiwayat();
      case _Tab.rekap:
        return _buildTabRekap();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB INPUT — mirror web tab === "input"
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabInput() {
    return Consumer<VocationalProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Form filter (kelas, tanggal, deskripsi)
            _buildInputForm(provider),
            const SizedBox(height: 12),
            // Summary cards (hanya tampil jika kelas dipilih)
            if (_selectedKelasId.isNotEmpty) ...[
              _buildSummaryCards(provider),
              const SizedBox(height: 12),
              // Daftar siswa
              _buildSiswaSection(provider),
            ],
          ],
        );
      },
    );
  }

  /// Form: Kelas + Tanggal + Deskripsi — mirror web grid-cols-3
  Widget _buildInputForm(VocationalProvider provider) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown Kelas
          _FieldLabel(label: 'Kelas'),
          const SizedBox(height: 6),
          _buildKelasDropdown(
            value: _selectedKelasId.isEmpty ? null : _selectedKelasId,
            hintText: '-- Pilih Kelas --',
            onChanged: (val) {
              final id = val ?? '';
              setState(() => _selectedKelasId = id);
              if (id.isEmpty) {
                provider.clearSiswaList();
              } else {
                provider.loadSiswaPramuka(id);
              }
            },
            provider: provider,
          ),
          const SizedBox(height: 14),

          // Tanggal Kegiatan — mirror web date input
          _FieldLabel(label: 'Tanggal Kegiatan'),
          const SizedBox(height: 6),
          _buildDatePicker(
            value: _tanggal,
            onChanged: (val) => setState(() => _tanggal = val),
          ),
          const SizedBox(height: 14),

          // Deskripsi Kegiatan
          _FieldLabel(label: 'Deskripsi Kegiatan'),
          const SizedBox(height: 6),
          TextField(
            controller: _deskripsiCtrl,
            decoration: _inputDecoration('Contoh: Baris-berbaris, P3K...'),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Summary 6 kotak — mirror web grid-cols-6 summary cards
  Widget _buildSummaryCards(VocationalProvider provider) {
    final s = provider.absensiSummary;
    final items = [
      (label: 'Total', value: s['total'] ?? 0, color: AppColors.grey900, bg: AppColors.surface, border: AppColors.grey300),
      (label: 'Belum', value: s['belum'] ?? 0, color: AppColors.grey700, bg: AppColors.grey100, border: AppColors.grey300),
      (label: 'Hadir', value: s['hadir'] ?? 0, color: const Color(0xFF2E7D32), bg: const Color(0xFFE8F5E9), border: const Color(0xFFA5D6A7)),
      (label: 'Izin', value: s['izin'] ?? 0, color: const Color(0xFFF57F17), bg: const Color(0xFFFFF8E1), border: const Color(0xFFFFE082)),
      (label: 'Sakit', value: s['sakit'] ?? 0, color: AppColors.primary, bg: const Color(0xFFE3F2FD), border: const Color(0xFF90CAF9)),
      (label: 'Alpa', value: s['alpa'] ?? 0, color: AppColors.error, bg: AppColors.errorLight, border: const Color(0xFFEF9A9A)),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            width: 72,
            decoration: BoxDecoration(
              color: item.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: item.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: item.color.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.value}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: item.color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Daftar siswa + tombol tandai semua + tombol simpan — mirror web table
  Widget _buildSiswaSection(VocationalProvider provider) {
    final namaKelas = provider.getNamaKelasById(_selectedKelasId);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: nama kelas + tanggal + tombol tandai semua
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Siswa — $namaKelas',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tanggal,
                      style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tombol tandai semua — mirror web flex-wrap gap-2
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _statusOpts.map((status) {
              return GestureDetector(
                onTap: () => provider.tandaiSemuaStatus(status),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor[status],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Semua ${_statusLabel[status]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

          // Body: loading / empty / list siswa
          if (provider.loadingSiswa)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.siswaList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Tidak ada siswa di kelas ini.',
                  style: TextStyle(color: AppColors.grey500),
                ),
              ),
            )
          else ...[
            // Column header — mirror web thead
            const _SiswaRowHeader(),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            // Rows
            ...provider.siswaList.asMap().entries.map((entry) {
              final index = entry.key;
              final siswa = entry.value;
              final statusNow = provider.absensiMap[siswa.id]?['status'] ?? '';
              final keteranganNow = provider.absensiMap[siswa.id]?['keterangan'] ?? '';
              return _SiswaRow(
                nomor: index + 1,
                nama: siswa.namaLengkap,
                nisn: siswa.nisn ?? '-',
                selectedStatus: statusNow,
                keterangan: keteranganNow,
                onStatusTap: (s) => provider.setAbsensiStatus(siswa.id, s),
                onKeteranganChanged: (k) => provider.setAbsensiKeterangan(siswa.id, k),
              );
            }),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            // Tombol simpan — mirror web px-6 py-4 flex justify-end
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 180,
                  child: ElevatedButton.icon(
                    onPressed: provider.saving ? null : () => _handleSimpan(provider),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text(provider.saving ? 'Menyimpan...' : 'Simpan Absensi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSimpan(VocationalProvider provider) async {
    if (_selectedKelasId.isEmpty) {
      _showSnack('Pilih kelas terlebih dahulu', isError: true);
      return;
    }
    final (success, errMsg) = await provider.submitAbsensiPramukaBulk(
      kelasId: _selectedKelasId,
      tanggal: _tanggal,
      deskripsi: _deskripsiCtrl.text.trim(),
    );

    if (success) {
      _showSnack('Absensi pramuka berhasil disimpan');
      _deskripsiCtrl.clear();

      // Auto-populate riwayat & rekap filter lalu switch — mirror web behavior
      setState(() {
        _riwayatKelasId = _selectedKelasId;
        _riwayatTanggal = _tanggal;
        _rekapKelasId = _selectedKelasId;
        _rekapMulai = _tanggal;
        _rekapAkhir = _tanggal;
      });

      await Future.wait([
        provider.loadRiwayatAbsensi(kelasId: _selectedKelasId, tanggal: _tanggal),
        provider.loadRekapAbsensi(kelasId: _selectedKelasId, tanggalMulai: _tanggal, tanggalAkhir: _tanggal),
      ]);
    } else {
      _showSnack(errMsg ?? 'Gagal menyimpan absensi', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB RIWAYAT — mirror web tab === "riwayat"
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabRiwayat() {
    return Consumer<VocationalProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Riwayat Absensi',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.grey900),
                  ),
                  const SizedBox(height: 14),
                  // Kelas
                  _FieldLabel(label: 'Kelas'),
                  const SizedBox(height: 6),
                  _buildKelasDropdown(
                    value: _riwayatKelasId.isEmpty ? null : _riwayatKelasId,
                    hintText: 'Semua Kelas',
                    onChanged: (val) => setState(() => _riwayatKelasId = val ?? ''),
                    provider: provider,
                    allowNull: true,
                  ),
                  const SizedBox(height: 14),
                  // Tanggal
                  _FieldLabel(label: 'Tanggal'),
                  const SizedBox(height: 6),
                  _buildDatePicker(
                    value: _riwayatTanggal,
                    hintText: 'Semua tanggal',
                    onChanged: (val) => setState(() => _riwayatTanggal = val),
                    allowClear: true,
                  ),
                  const SizedBox(height: 14),
                  // Tombol tampilkan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.loadingRiwayat
                          ? null
                          : () => provider.loadRiwayatAbsensi(
                                kelasId: _riwayatKelasId.isEmpty ? null : _riwayatKelasId,
                                tanggal: _riwayatTanggal.isEmpty ? null : _riwayatTanggal,
                              ),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text(provider.loadingRiwayat ? 'Memuat...' : 'Tampilkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tabel riwayat
            _Card(
              padding: EdgeInsets.zero,
              child: provider.loadingRiwayat
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : provider.riwayatAbsensi.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Klik Tampilkan untuk melihat riwayat absensi.',
                              style: TextStyle(color: AppColors.grey500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _buildRiwayatTable(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRiwayatTable(VocationalProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
          DataColumn(label: Text('Nama Siswa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
          DataColumn(label: Text('Kelas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
          DataColumn(label: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
        ],
        rows: provider.riwayatAbsensi.map((item) {
          return DataRow(cells: [
            DataCell(Text(item.tanggal, style: const TextStyle(fontSize: 13, color: AppColors.grey700))),
            DataCell(Text(item.namaLengkap, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey900))),
            DataCell(Text(
              item.kelasId != null ? provider.getNamaKelasById(item.kelasId!) : '-',
              style: const TextStyle(fontSize: 13, color: AppColors.grey500),
            )),
            DataCell(_StatusBadge(status: item.status)),
            DataCell(Text(item.keterangan ?? '-', style: const TextStyle(fontSize: 13, color: AppColors.grey500))),
          ]);
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB REKAP — mirror web tab === "rekap"
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabRekap() {
    return Consumer<VocationalProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rekap Absensi Pramuka',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.grey900),
                  ),
                  const SizedBox(height: 14),
                  // Kelas (wajib)
                  _FieldLabel(label: 'Kelas'),
                  const SizedBox(height: 6),
                  _buildKelasDropdown(
                    value: _rekapKelasId.isEmpty ? null : _rekapKelasId,
                    hintText: '-- Pilih Kelas --',
                    onChanged: (val) => setState(() => _rekapKelasId = val ?? ''),
                    provider: provider,
                  ),
                  const SizedBox(height: 14),
                  // Tanggal Mulai
                  _FieldLabel(label: 'Tanggal Mulai'),
                  const SizedBox(height: 6),
                  _buildDatePicker(
                    value: _rekapMulai,
                    hintText: 'Pilih tanggal mulai',
                    onChanged: (val) => setState(() => _rekapMulai = val),
                    allowClear: true,
                  ),
                  const SizedBox(height: 14),
                  // Tanggal Akhir
                  _FieldLabel(label: 'Tanggal Akhir'),
                  const SizedBox(height: 6),
                  _buildDatePicker(
                    value: _rekapAkhir,
                    hintText: 'Pilih tanggal akhir',
                    onChanged: (val) => setState(() => _rekapAkhir = val),
                    allowClear: true,
                  ),
                  const SizedBox(height: 14),
                  // Tombol tampilkan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.loadingRekap || _rekapKelasId.isEmpty
                          ? null
                          : () => provider.loadRekapAbsensi(
                                kelasId: _rekapKelasId,
                                tanggalMulai: _rekapMulai.isEmpty ? null : _rekapMulai,
                                tanggalAkhir: _rekapAkhir.isEmpty ? null : _rekapAkhir,
                              ),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text(provider.loadingRekap ? 'Memuat...' : 'Tampilkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tabel rekap
            _Card(
              padding: EdgeInsets.zero,
              child: provider.loadingRekap
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : provider.rekapSiswaList.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Pilih kelas lalu klik Tampilkan untuk melihat rekap.',
                              style: TextStyle(color: AppColors.grey500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _buildRekapTable(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRekapTable(VocationalProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
          DataColumn(label: Text('Nama Siswa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
          DataColumn(label: Text('NISN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
          DataColumn(label: Text('Hadir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF2E7D32)))),
          DataColumn(label: Text('Izin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFFF57F17)))),
          DataColumn(label: Text('Sakit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.primary))),
          DataColumn(label: Text('Alpa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.error))),
          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
        ],
        rows: provider.rekapSiswaList.asMap().entries.map((entry) {
          final index = entry.key;
          final siswa = entry.value;
          final data = provider.getRekapBySiswaId(siswa.id);
          return DataRow(cells: [
            DataCell(Text('${index + 1}', style: const TextStyle(fontSize: 13, color: AppColors.grey500))),
            DataCell(Text(siswa.namaLengkap, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey900))),
            DataCell(Text(siswa.nisn ?? '-', style: const TextStyle(fontSize: 13, color: AppColors.grey500))),
            DataCell(Text('${data?.hadir ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)))),
            DataCell(Text('${data?.izin ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFF57F17)))),
            DataCell(Text('${data?.sakit ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
            DataCell(Text('${data?.alpa ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error))),
            DataCell(Text('${data?.total ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900))),
          ]);
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Shared UI helpers
  // ─────────────────────────────────────────────────────────────
  Widget _buildKelasDropdown({
    required String? value,
    required String hintText,
    required ValueChanged<String?> onChanged,
    required VocationalProvider provider,
    bool allowNull = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(hintText),
      isExpanded: true,
      hint: Text(hintText, style: const TextStyle(fontSize: 14)),
      items: [
        if (allowNull)
          const DropdownMenuItem<String>(value: null, child: Text('Semua Kelas')),
        ...provider.kelasVokasionalList.map((k) {
          return DropdownMenuItem<String>(
            value: k.id,
            child: Text(k.namaKelas, style: const TextStyle(fontSize: 14)),
          );
        }),
      ],
      onChanged: provider.loadingKelas ? null : onChanged,
      style: const TextStyle(fontSize: 14, color: AppColors.grey900),
    );
  }

  Widget _buildDatePicker({
    required String value,
    String? hintText,
    required ValueChanged<String> onChanged,
    bool allowClear = false,
  }) {
    return GestureDetector(
      onTap: () async {
        DateTime initial;
        try {
          initial = value.isNotEmpty ? DateTime.parse(value) : DateTime.now();
        } catch (_) {
          initial = DateTime.now();
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onChanged(DateFormat('yyyy-MM-dd').format(picked));
        }
      },
      child: AbsorbPointer(
        child: TextField(
          decoration: _inputDecoration(hintText ?? 'Pilih tanggal').copyWith(
            suffixIcon: allowClear && value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onChanged(''),
                  )
                : const Icon(Icons.calendar_today_rounded, size: 18),
          ),
          controller: TextEditingController(text: value),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: AppColors.grey500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.white,
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }
}

// ═══════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.grey500,
      ),
    );
  }
}

/// Header row untuk tabel siswa (non-scrollable, column-based)
class _SiswaRowHeader extends StatelessWidget {
  const _SiswaRowHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Row(
        children: [
          SizedBox(width: 32, child: Text('No', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey500))),
          Expanded(flex: 3, child: Text('Nama Siswa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey500))),
          Expanded(flex: 2, child: Text('NISN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey500))),
          Expanded(flex: 4, child: Center(child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey500)))),
        ],
      ),
    );
  }
}

/// Row satu siswa — mirror web tbody tr
class _SiswaRow extends StatefulWidget {
  final int nomor;
  final String nama;
  final String nisn;
  final String selectedStatus;
  final String keterangan;
  final ValueChanged<String> onStatusTap;
  final ValueChanged<String> onKeteranganChanged;

  const _SiswaRow({
    required this.nomor,
    required this.nama,
    required this.nisn,
    required this.selectedStatus,
    required this.keterangan,
    required this.onStatusTap,
    required this.onKeteranganChanged,
  });

  @override
  State<_SiswaRow> createState() => _SiswaRowState();
}

class _SiswaRowState extends State<_SiswaRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.keterangan);
  }

  @override
  void didUpdateWidget(_SiswaRow old) {
    super.didUpdateWidget(old);
    if (widget.keterangan != _ctrl.text) {
      _ctrl.text = widget.keterangan;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row: No | Nama | NISN | Tombol status
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                child: Text('${widget.nomor}', style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  widget.nama,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(widget.nisn, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
              ),
              // Tombol status — mirror web STATUS_OPTS buttons
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _statusOpts.map((status) {
                    final isActive = widget.selectedStatus == status;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: () => widget.onStatusTap(status),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          decoration: BoxDecoration(
                            color: isActive ? _statusColor[status] : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (_statusLabel[status] ?? status).substring(0, 1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : AppColors.grey500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Keterangan input — mirror web input keterangan per baris
        Padding(
          padding: const EdgeInsets.fromLTRB(44, 0, 12, 8),
          child: TextField(
            controller: _ctrl,
            onChanged: widget.onKeteranganChanged,
            decoration: InputDecoration(
              hintText: 'Keterangan (opsional)',
              hintStyle: const TextStyle(fontSize: 11, color: AppColors.grey400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.grey300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.grey300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
              filled: true,
              fillColor: AppColors.white,
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
      ],
    );
  }
}

/// Badge status — mirror web STATUS_BADGE
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor[status] ?? AppColors.grey500;
    final bg = _statusBgColor[status] ?? AppColors.grey100;
    final label = _statusLabel[status] ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}