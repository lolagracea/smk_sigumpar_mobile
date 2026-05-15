import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../academic/providers/academic_provider.dart';
import '../providers/student_provider.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  String? _selectedClassId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final academic = context.read<AcademicProvider>();
    await academic.fetchClasses(refresh: true);
    if (academic.classes.isNotEmpty) {
      setState(() => _selectedClassId = academic.classes.first.id);
      _fetchData();
    }
  }

  void _fetchData() {
    if (_selectedClassId == null) return;
    context.read<StudentProvider>().fetchAttendanceSummary(
      classId: _selectedClassId!,
      tanggalMulai: _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null,
      tanggalAkhir: _endDate != null
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null,
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchData();
  }

  // Pakai == bukan contains — karena _parseError sudah mengembalikan
  // string yang terdefinisi jelas sehingga tidak ada false positive.
  bool _isNotAssignedError(String? msg) => msg == 'Akses ditolak';
  bool _isConnectionError(String? msg) =>
      msg == 'Tidak ada koneksi internet' || msg == 'Server tidak merespon';
  bool _isSessionError(String? msg) => msg == 'Sesi habis, silakan login ulang';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ─── Filter Bar ───────────────────────────────────
        Container(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Consumer<AcademicProvider>(
                builder: (context, academic, _) {
                  if (academic.classes.isEmpty) return const SizedBox.shrink();
                  return DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    dropdownColor:
                    isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Pilih Kelas',
                      labelStyle: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade600),
                      prefixIcon: Icon(Icons.class_outlined,
                          color: isDark ? Colors.white54 : Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: academic.classes.map((c) {
                      return DropdownMenuItem(
                          value: c.id, child: Text(c.namaKelas));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedClassId = val);
                      _fetchData();
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.date_range,
                                size: 18,
                                color:
                                isDark ? Colors.white54 : Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _startDate == null
                                    ? 'Filter Rentang Tanggal'
                                    : '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _startDate == null
                                      ? (isDark
                                      ? Colors.white38
                                      : Colors.grey.shade500)
                                      : (isDark
                                      ? Colors.white
                                      : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_startDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearFilter,
                      icon: Icon(Icons.clear,
                          color: isDark ? Colors.white54 : Colors.grey),
                      tooltip: 'Hapus filter',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // ─── Content ──────────────────────────────────────
        Expanded(
          child: Consumer<StudentProvider>(
            builder: (context, provider, _) {
              // ── Loading ──────────────────────────────────
              if (provider.summaryState == StudentLoadState.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              // ── Error State ──────────────────────────────
              if (provider.summaryState == StudentLoadState.error) {
                final errorMsg = provider.summaryError;
                final isNotAssigned = _isNotAssignedError(errorMsg);
                final isConnection = _isConnectionError(errorMsg);
                final isSession = _isSessionError(errorMsg);

                final IconData icon;
                final Color iconColor;
                final String title;
                final String subtitle;

                if (isNotAssigned) {
                  icon = Icons.admin_panel_settings_outlined;
                  iconColor = isDark
                      ? Colors.orange.shade300
                      : Colors.orange.shade600;
                  title = 'Akses Tidak Diizinkan';
                  subtitle =
                  'Anda bukan wali kelas yang ditugaskan untuk kelas ini. '
                      'Silakan pilih kelas lain yang sesuai dengan penugasan Anda.';
                } else if (isSession) {
                  icon = Icons.lock_outline_rounded;
                  iconColor =
                  isDark ? Colors.amber.shade300 : Colors.amber.shade700;
                  title = 'Sesi Berakhir';
                  subtitle =
                  'Sesi Anda telah habis. Silakan login ulang untuk melanjutkan.';
                } else if (isConnection) {
                  icon = errorMsg == 'Server tidak merespon'
                      ? Icons.cloud_off_rounded
                      : Icons.wifi_off_rounded;
                  iconColor =
                  isDark ? Colors.red.shade300 : Colors.red.shade500;
                  title = errorMsg == 'Server tidak merespon'
                      ? 'Server Tidak Merespon'
                      : 'Tidak Ada Koneksi';
                  subtitle = errorMsg == 'Server tidak merespon'
                      ? 'Server sedang tidak merespon. Coba lagi beberapa saat.'
                      : 'Periksa koneksi internet Anda, lalu coba lagi.';
                } else {
                  icon = Icons.error_outline_rounded;
                  iconColor =
                  isDark ? Colors.red.shade300 : Colors.red.shade500;
                  title = 'Gagal Memuat Data';
                  subtitle = errorMsg?.isNotEmpty == true
                      ? errorMsg!
                      : 'Terjadi kesalahan saat memuat data absensi.';
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 52, color: iconColor),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!isNotAssigned && !isSession)
                          ElevatedButton.icon(
                            onPressed: _fetchData,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Coba Lagi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        if (isNotAssigned)
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.swap_horiz,
                                size: 18, color: iconColor),
                            label: Text('Ganti Kelas',
                                style: TextStyle(color: iconColor)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: iconColor.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }

              // ── Empty State ──────────────────────────────
              if (provider.summaries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.event_busy_outlined,
                            size: 52,
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Belum Ada Data Absensi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color:
                            isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _startDate != null
                              ? 'Tidak ada data absensi pada rentang tanggal yang dipilih.\nCoba ubah atau hapus filter tanggal.'
                              : 'Data absensi untuk kelas ini belum tersedia.\nPastikan kelas ini adalah kelas yang Anda ampu sebagai wali kelas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                          ),
                        ),
                        if (_startDate != null) ...[
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: _clearFilter,
                            icon:
                            const Icon(Icons.filter_alt_off, size: 16),
                            label: const Text('Hapus Filter Tanggal'),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              // ── Data tersedia ─────────────────────────────
              return RefreshIndicator(
                onRefresh: () async => _fetchData(),
                child: Column(
                  children: [
                    Container(
                      color: isDark
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: const [
                          SizedBox(
                              width: 28,
                              child: Text('No', style: _headerStyle)),
                          Expanded(
                              child: Text('Nama Siswa',
                                  style: _headerStyle)),
                          _HeaderCell('H'),
                          _HeaderCell('S'),
                          _HeaderCell('I'),
                          _HeaderCell('A'),
                          _HeaderCell('Total'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: provider.summaries.length,
                        itemBuilder: (context, index) {
                          final s = provider.summaries[index];
                          final isEven = index % 2 == 0;
                          final rowColor = isDark
                              ? (isEven
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF0F172A))
                              : (isEven
                              ? Colors.white
                              : Colors.grey.shade50);
                          final total = s.present +
                              s.sick +
                              s.permission +
                              s.absent;

                          return Container(
                            color: rowColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text('${index + 1}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey)),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.studentName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (s.nisn != null)
                                        Text(
                                          'NISN: ${s.nisn}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                _StatusCell(
                                    value: s.present,
                                    color: Colors.green,
                                    isDark: isDark),
                                _StatusCell(
                                    value: s.sick,
                                    color: Colors.blue,
                                    isDark: isDark),
                                _StatusCell(
                                    value: s.permission,
                                    color: Colors.orange,
                                    isDark: isDark),
                                _StatusCell(
                                    value: s.absent,
                                    color: Colors.red,
                                    isDark: isDark),
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    '$total',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

const _headerStyle = TextStyle(
  color: Colors.white,
  fontSize: 11,
  fontWeight: FontWeight.bold,
);

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Text(label,
          textAlign: TextAlign.center, style: _headerStyle),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final int value;
  final MaterialColor color;
  final bool isDark;
  const _StatusCell(
      {required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Center(
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: value > 0
                ? (isDark ? color.withOpacity(0.2) : color.shade50)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
              value > 0 ? FontWeight.bold : FontWeight.normal,
              color: value > 0
                  ? (isDark ? color.shade300 : color.shade700)
                  : (isDark
                  ? Colors.white38
                  : Colors.grey.shade400),
            ),
          ),
        ),
      ),
    );
  }
}