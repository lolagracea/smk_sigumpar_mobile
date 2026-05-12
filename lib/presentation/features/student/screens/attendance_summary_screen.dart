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
              if (provider.summaryState == StudentLoadState.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.summaryState == StudentLoadState.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color: isDark
                              ? Colors.red.shade300
                              : Colors.red.shade400),
                      const SizedBox(height: 12),
                      Text(
                        provider.summaryError ?? 'Gagal memuat data',
                        style: TextStyle(
                            color: isDark
                                ? Colors.red.shade300
                                : Colors.red.shade600),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.summaries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64,
                          color: isDark
                              ? Colors.white24
                              : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada data absensi',
                        style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _fetchData(),
                child: Column(
                  children: [
                    // Header tabel
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
                              child:
                              Text('Nama Siswa', style: _headerStyle)),
                          _HeaderCell('H'),
                          _HeaderCell('S'),
                          _HeaderCell('I'),
                          _HeaderCell('A'),
                          _HeaderCell('Total'),
                        ],
                      ),
                    ),
                    // List data
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
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey),
                                  ),
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
      child:
      Text(label, textAlign: TextAlign.center, style: _headerStyle),
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