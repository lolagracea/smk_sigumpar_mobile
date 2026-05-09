import 'package:flutter/material.dart';

// ============================================================
// MODEL
// ============================================================
class NilaiSiswa {
  final String nis;
  final String nama;
  final Map<String, double> nilaiPerMapel; // mapel -> nilai

  NilaiSiswa({required this.nis, required this.nama, required this.nilaiPerMapel});

  double get rataRata {
    if (nilaiPerMapel.isEmpty) return 0;
    return nilaiPerMapel.values.reduce((a, b) => a + b) / nilaiPerMapel.length;
  }
}

class RiwayatRekap {
  final String kelas;
  final String mapel;
  final String tahunAjar;
  final DateTime tanggal;
  final int jumlahSiswa;

  RiwayatRekap({
    required this.kelas,
    required this.mapel,
    required this.tahunAjar,
    required this.tanggal,
    required this.jumlahSiswa,
  });
}

// ============================================================
// SCREEN
// ============================================================
class RekapNilaiScreen extends StatefulWidget {
  const RekapNilaiScreen({super.key});

  @override
  State<RekapNilaiScreen> createState() => _RekapNilaiScreenState();
}

class _RekapNilaiScreenState extends State<RekapNilaiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter state
  String? _selectedKelas;
  String _selectedMapel = 'Semua Mapel';
  String _selectedTahun = '2024/2025';

  bool _isLoading = false;
  bool _hasData = false;
  List<NilaiSiswa> _nilaiList = [];

  // Dropdown options
  final List<String> _kelasList = [
    'X TKJ 1', 'X TKJ 2', 'X RPL 1', 'X RPL 2',
    'XI TKJ 1', 'XI TKJ 2', 'XI RPL 1', 'XI RPL 2',
    'XII TKJ 1', 'XII TKJ 2', 'XII RPL 1', 'XII RPL 2',
  ];

  final List<String> _mapelList = [
    'Semua Mapel', 'Matematika', 'Bahasa Indonesia', 'Bahasa Inggris',
    'Fisika', 'Kimia', 'PKK', 'Pemrograman Web', 'Basis Data',
  ];

  final List<String> _tahunList = ['2024/2025', '2023/2024', '2022/2023'];

  // Dummy riwayat
  final List<RiwayatRekap> _riwayat = [
    RiwayatRekap(
      kelas: 'XI TKJ 1', mapel: 'Matematika', tahunAjar: '2024/2025',
      tanggal: DateTime(2025, 3, 15), jumlahSiswa: 30,
    ),
    RiwayatRekap(
      kelas: 'X RPL 2', mapel: 'Semua Mapel', tahunAjar: '2024/2025',
      tanggal: DateTime(2025, 2, 20), jumlahSiswa: 28,
    ),
    RiwayatRekap(
      kelas: 'XII TKJ 1', mapel: 'Basis Data', tahunAjar: '2023/2024',
      tanggal: DateTime(2024, 11, 5), jumlahSiswa: 32,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _tampilkanRekap() {
    if (_selectedKelas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kelas terlebih dahulu'),
          backgroundColor: Color(0xFFE53E3E),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        _isLoading = false;
        _hasData = true;
        _nilaiList = _generateDummyNilai(_selectedMapel);
      });
    });
  }

  List<NilaiSiswa> _generateDummyNilai(String mapel) {
    final names = [
      'Ahmad Fauzi', 'Budi Santoso', 'Cahya Permata', 'Dian Lestari',
      'Eka Putra', 'Fitri Handayani', 'Gilang Ramadhan', 'Hana Sari',
      'Ivan Kurniawan', 'Joko Widodo', 'Kartika Dewi', 'Luki Pratama',
    ];

    if (mapel == 'Semua Mapel') {
      final mapels = ['Matematika', 'B. Indonesia', 'B. Inggris', 'Fisika'];
      return names.asMap().entries.map((e) {
        final r = e.key;
        return NilaiSiswa(
          nis: '2024${(r + 1).toString().padLeft(3, '0')}',
          nama: e.value,
          nilaiPerMapel: {
            for (var m in mapels)
              m: 60 + (r * 3 + mapels.indexOf(m) * 5) % 40 + 0.0
          },
        );
      }).toList();
    } else {
      return names.asMap().entries.map((e) {
        final r = e.key;
        return NilaiSiswa(
          nis: '2024${(r + 1).toString().padLeft(3, '0')}',
          nama: e.value,
          nilaiPerMapel: {mapel: 60 + (r * 7) % 40 + 0.0},
        );
      }).toList();
    }
  }

  Color _nilaiColor(double nilai) {
    if (nilai >= 85) return const Color(0xFF38A169);
    if (nilai >= 70) return const Color(0xFF3182CE);
    if (nilai >= 60) return const Color(0xFFD69E2E);
    return const Color(0xFFE53E3E);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        title: const Text(
          'Rekap Nilai',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3182CE),
          unselectedLabelColor: const Color(0xFF718096),
          indicatorColor: const Color(0xFF3182CE),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Rekap Nilai'),
            Tab(icon: Icon(Icons.history, size: 18), text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRekapTab(),
          _buildRiwayatTab(),
        ],
      ),
    );
  }

  // ---- TAB 1: Rekap Nilai ----
  Widget _buildRekapTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _HeaderCard(
            title: 'Rekap Nilai Siswa (Wali Kelas)',
            subtitle: 'Tampilkan rekap nilai berdasarkan kelas dan mata pelajaran.',
            icon: Icons.assessment_rounded,
            iconColor: const Color(0xFF3182CE),
          ),
          const SizedBox(height: 16),

          // Filter card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row: Kelas + Mapel
                  Row(
                    children: [
                      Expanded(child: _FilterDropdown(
                        label: 'KELAS',
                        hint: '-- Pilih Kelas --',
                        value: _selectedKelas,
                        items: _kelasList,
                        onChanged: (v) => setState(() { _selectedKelas = v; _hasData = false; }),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _FilterDropdown(
                        label: 'MATA PELAJARAN',
                        hint: null,
                        value: _selectedMapel,
                        items: _mapelList,
                        onChanged: (v) => setState(() { _selectedMapel = v!; _hasData = false; }),
                      )),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tahun Ajar
                  _FilterDropdown(
                    label: 'TAHUN AJAR',
                    hint: null,
                    value: _selectedTahun,
                    items: _tahunList,
                    onChanged: (v) => setState(() { _selectedTahun = v!; _hasData = false; }),
                  ),
                  const SizedBox(height: 16),

                  // Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _tampilkanRekap,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.bar_chart, size: 18),
                    label: Text(_isLoading ? 'Memuat...' : 'Tampilkan Rekap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3182CE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Result area
          _hasData ? _buildNilaiTable() : _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assessment_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text(
                'Pilih Kelas dan Tahun Ajar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'lalu klik Tampilkan Rekap',
                style: TextStyle(fontSize: 12, color: Color(0xFFA0AEC0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNilaiTable() {
    final mapels = _nilaiList.isNotEmpty ? _nilaiList.first.nilaiPerMapel.keys.toList() : <String>[];
    final showAvg = mapels.length > 1;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary stats
            Row(
              children: [
                _StatChip(label: 'Siswa', value: '${_nilaiList.length}', color: const Color(0xFF3182CE)),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Rata-rata',
                  value: _nilaiList.isEmpty ? '-' : (_nilaiList.map((s) => s.rataRata).reduce((a, b) => a + b) / _nilaiList.length).toStringAsFixed(1),
                  color: const Color(0xFF38A169),
                ),
                const SizedBox(width: 8),
                _StatChip(label: 'Kelas', value: _selectedKelas ?? '-', color: const Color(0xFFD69E2E)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),

            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 28, child: Text('No', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                  const Expanded(flex: 3, child: Text('Nama Siswa', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                  ...mapels.map((m) => Expanded(
                    flex: 2,
                    child: Text(m, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                  )),
                  if (showAvg)
                    const Expanded(
                      flex: 2,
                      child: Text('Rata', style: TextStyle(color: Color(0xFFECC94B), fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Table rows
            ..._nilaiList.asMap().entries.map((entry) {
              final i = entry.key;
              final siswa = entry.value;
              final isEven = i % 2 == 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isEven ? const Color(0xFFF7FAFC) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(siswa.nama, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                          Text(siswa.nis, style: const TextStyle(fontSize: 10, color: Color(0xFF718096))),
                        ],
                      ),
                    ),
                    ...mapels.map((m) {
                      final val = siswa.nilaiPerMapel[m] ?? 0;
                      return Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: _nilaiColor(val).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              val.toStringAsFixed(0),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _nilaiColor(val),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (showAvg)
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            siswa.rataRata.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _nilaiColor(siswa.rataRata),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _LegendItem(color: const Color(0xFF38A169), label: '≥ 85 (Sangat Baik)'),
                _LegendItem(color: const Color(0xFF3182CE), label: '70–84 (Baik)'),
                _LegendItem(color: const Color(0xFFD69E2E), label: '60–69 (Cukup)'),
                _LegendItem(color: const Color(0xFFE53E3E), label: '< 60 (Kurang)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- TAB 2: Riwayat ----
  Widget _buildRiwayatTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(
            title: 'Riwayat Rekap Nilai',
            subtitle: 'Daftar rekap nilai yang pernah ditampilkan.',
            icon: Icons.history_rounded,
            iconColor: const Color(0xFF805AD5),
          ),
          const SizedBox(height: 16),

          if (_riwayat.isEmpty)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text('Belum ada riwayat rekap.', style: TextStyle(color: Color(0xFFA0AEC0))),
                ),
              ),
            )
          else
            ..._riwayat.map((r) => _RiwayatCard(rekap: r)),
        ],
      ),
    );
  }
}

// ============================================================
// HELPER WIDGETS
// ============================================================

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: iconColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2D3748))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF718096),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCBD5E0)),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF7FAFC),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: hint != null
                  ? Text(hint!, style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13))
                  : null,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF718096), size: 18),
              style: const TextStyle(fontSize: 13, color: Color(0xFF2D3748)),
              items: items.map((k) => DropdownMenuItem(value: k, child: Text(k, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
      ],
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  final RiwayatRekap rekap;

  const _RiwayatCard({required this.rekap});

  @override
  Widget build(BuildContext context) {
    final tanggal = '${rekap.tanggal.day}/${rekap.tanggal.month}/${rekap.tanggal.year}';
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF805AD5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined, color: Color(0xFF805AD5), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rekap.kelas} — ${rekap.mapel}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tahun ${rekap.tahunAjar} • ${rekap.jumlahSiswa} siswa',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                  ),
                  Text(
                    tanggal,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFA0AEC0)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.visibility_outlined, color: Color(0xFF3182CE), size: 20),
              onPressed: () {},
              tooltip: 'Lihat Detail',
            ),
          ],
        ),
      ),
    );
  }
}