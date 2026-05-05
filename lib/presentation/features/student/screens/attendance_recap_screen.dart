import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/repositories/student_repository.dart';
import '../providers/student_provider.dart';

// ─── Entry point ─────────────────────────────────────────────────
class AttendanceRecapScreen extends StatelessWidget {
  const AttendanceRecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentProvider(repository: sl<StudentRepository>())
        ..loadSchedules(),
      child: const _AttendanceView(),
    );
  }
}

// ─── Main View ───────────────────────────────────────────────────
class _AttendanceView extends StatefulWidget {
  const _AttendanceView();

  @override
  State<_AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<_AttendanceView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _AttendanceTab(),
              _HistoryTab(),
              _RecapTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.edit_calendar_outlined), text: 'Attendance'),
          Tab(icon: Icon(Icons.history_outlined), text: 'History'),
          Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Recap'),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TAB 1 — ATTENDANCE INPUT
// ════════════════════════════════════════════════════════════════
class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    return Column(
      children: [
        const _ScheduleFilterSection(),
        if (provider.selectedSchedule != null) const _AttendanceSummaryBar(),
        const Expanded(child: _StudentAttendanceList()),
        if (provider.selectedSchedule != null &&
            provider.studentList.isNotEmpty)
          const _SaveAttendanceButton(),
      ],
    );
  }
}

// ─── Filter: schedule dropdown + date picker ─────────────────────
class _ScheduleFilterSection extends StatelessWidget {
  const _ScheduleFilterSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<Map<String, dynamic>>(
            value: provider.selectedSchedule,
            decoration: InputDecoration(
              labelText: 'Subject Schedule',
              prefixIcon: const Icon(Icons.schedule_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            hint: const Text('Select Schedule'),
            isExpanded: true,
            items: provider.scheduleList.map((j) {
              final label =
                  '${j['hari'] ?? ''} • ${j['jam_mulai'] ?? ''} - ${j['jam_selesai'] ?? ''} • ${j['nama_mapel'] ?? ''} • ${j['nama_kelas'] ?? ''}';
              return DropdownMenuItem<Map<String, dynamic>>(
                value: j,
                child: Text(label,
                    overflow: TextOverflow.ellipsis, maxLines: 1),
              );
            }).toList(),
            onChanged: provider.scheduleState == StudentLoadState.loading
                ? null
                : (val) {
              if (val != null) provider.selectSchedule(val);
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: provider.attendanceDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF2563EB),
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) provider.setAttendanceDate(picked);
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                        .format(provider.attendanceDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary bar ─────────────────────────────────────────────────
class _AttendanceSummaryBar extends StatelessWidget {
  const _AttendanceSummaryBar();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final counts = provider.attendanceStatusCounts;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          _SummaryChip(
              label: 'Total',
              value: provider.studentList.length,
              color: Colors.grey.shade700),
          _SummaryChip(
              label: 'Hadir',
              value: counts['hadir'] ?? 0,
              color: Colors.green.shade700),
          _SummaryChip(
              label: 'Izin',
              value: counts['izin'] ?? 0,
              color: Colors.blue.shade700),
          _SummaryChip(
              label: 'Sakit',
              value: counts['sakit'] ?? 0,
              color: Colors.orange.shade700),
          _SummaryChip(
              label: 'Alpa',
              value: counts['alpa'] ?? 0,
              color: Colors.red.shade700),
          _SummaryChip(
              label: 'Terlambat',
              value: counts['terlambat'] ?? 0,
              color: Colors.purple.shade700),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Student list ─────────────────────────────────────────────────
class _StudentAttendanceList extends StatelessWidget {
  const _StudentAttendanceList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    if (provider.selectedSchedule == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Pilih jadwal mapel untuk mulai absensi',
                style:
                TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      );
    }

    if (provider.studentListState == StudentLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.studentListError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: Colors.red.shade400, size: 48),
            const SizedBox(height: 12),
            Text(provider.studentListError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade600)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.reloadStudentList(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (provider.studentList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Tidak ada siswa di kelas ini',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                'Daftar Siswa  •  ${DateFormat('dd/MM/yyyy').format(provider.attendanceDate)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const Spacer(),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _QuickSetChip(
                  label: 'Semua Hadir',
                  status: 'hadir',
                  color: Colors.green.shade700),
              const SizedBox(width: 6),
              _QuickSetChip(
                  label: 'Semua Izin',
                  status: 'izin',
                  color: Colors.blue.shade700),
              const SizedBox(width: 6),
              _QuickSetChip(
                  label: 'Semua Sakit',
                  status: 'sakit',
                  color: Colors.orange.shade700),
              const SizedBox(width: 6),
              _QuickSetChip(
                  label: 'Semua Alpa',
                  status: 'alpa',
                  color: Colors.red.shade700),
              const SizedBox(width: 6),
              _QuickSetChip(
                  label: 'Semua Terlambat',
                  status: 'terlambat',
                  color: Colors.purple.shade700),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: provider.studentList.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final student = provider.studentList[index];
              return _StudentAttendanceRow(
                  index: index, student: student);
            },
          ),
        ),
      ],
    );
  }
}

class _QuickSetChip extends StatelessWidget {
  final String label;
  final String status;
  final Color color;
  const _QuickSetChip(
      {required this.label, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.read<StudentProvider>().setAllStudentStatus(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Row per student ──────────────────────────────────────────────
class _StudentAttendanceRow extends StatefulWidget {
  final int index;
  final Map<String, dynamic> student;
  const _StudentAttendanceRow(
      {required this.index, required this.student});

  @override
  State<_StudentAttendanceRow> createState() => _StudentAttendanceRowState();
}

class _StudentAttendanceRowState extends State<_StudentAttendanceRow> {
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  static const _statusConfig = {
    'hadir': {'label': 'Hadir', 'color': Colors.green},
    'izin': {'label': 'Izin', 'color': Colors.blue},
    'sakit': {'label': 'Sakit', 'color': Colors.orange},
    'alpa': {'label': 'Alpa', 'color': Colors.red},
    'terlambat': {'label': 'Terlambat', 'color': Colors.purple},
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final id = widget.student['id'].toString();
    final attData = provider.attendanceMap[id];
    final currentStatus = attData?['status'] ?? 'hadir';
    final isEven = widget.index % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isEven ? Colors.white : Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text('${widget.index + 1}',
                    style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.student['nama_lengkap']?.toString() ?? '-',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (widget.student['nisn'] != null)
                      Text('NISN: ${widget.student['nisn']}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 28),
              ..._statusConfig.entries.map((e) {
                final isSelected = currentStatus == e.key;
                final color = e.value['color'] as MaterialColor? ??
                    e.value['color'] as Color;
                final colorSwatch =
                color is MaterialColor ? color : Colors.grey;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      provider.updateStudentStatus(id, e.key);
                      setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (colorSwatch is MaterialColor
                            ? colorSwatch.shade600
                            : color)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorSwatch is MaterialColor
                              ? colorSwatch.shade400
                              : Colors.grey,
                          width: isSelected ? 0 : 1,
                        ),
                      ),
                      child: Text(
                        e.value['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (colorSwatch is MaterialColor
                              ? colorSwatch.shade700
                              : Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          if (currentStatus != 'hadir') ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: TextField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  hintText: 'Keterangan (opsional)',
                  hintStyle:
                  const TextStyle(fontSize: 12, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide:
                    BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (val) =>
                    provider.updateStudentNote(id, val),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────
class _SaveAttendanceButton extends StatelessWidget {
  const _SaveAttendanceButton();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: provider.isAttendanceSaving
              ? null
              : () async {
            final ok = await provider.saveAttendance();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok
                  ? 'Absensi berhasil disimpan!'
                  : provider.attendanceSaveError ??
                  'Gagal menyimpan absensi'),
              backgroundColor: ok ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating,
            ));
          },
          icon: provider.isAttendanceSaving
              ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(
            provider.isAttendanceSaving ? 'Menyimpan...' : 'Simpan Absensi',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TAB 2 — HISTORY
// ════════════════════════════════════════════════════════════════
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    if (provider.selectedSchedule == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Pilih jadwal di tab Attendance terlebih dahulu',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (provider.studentListState == StudentLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.studentList.isEmpty) {
      return const Center(
          child: Text('Belum ada data absensi',
              style: TextStyle(color: Colors.grey)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_outlined,
                    color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${provider.selectedSchedule!['hari'] ?? ''} • '
                        '${provider.selectedSchedule!['jam_mulai'] ?? ''} - '
                        '${provider.selectedSchedule!['jam_selesai'] ?? ''} • '
                        '${provider.selectedSchedule!['nama_mapel'] ?? ''} • '
                        '${provider.selectedSchedule!['nama_kelas'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Absensi — ${DateFormat('dd MMMM yyyy', 'id_ID').format(provider.attendanceDate)}',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                          width: 32,
                          child: Text('No',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text('Nama Siswa',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 80,
                          child: Text('Status',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 100,
                          child: Text('Keterangan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ...provider.studentList.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  final id = s['id'].toString();
                  final attData = provider.attendanceMap[id];
                  final status = attData?['status'] ?? '-';
                  final ket = attData?['keterangan'] ?? '';

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    color: i % 2 == 0
                        ? Colors.white
                        : Colors.grey.shade50,
                    child: Row(
                      children: [
                        SizedBox(
                            width: 32,
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey))),
                        Expanded(
                            child: Text(
                                s['nama_lengkap']?.toString() ?? '-',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis)),
                        SizedBox(
                          width: 80,
                          child: Center(
                              child: _StatusBadge(status: status)),
                        ),
                        SizedBox(
                            width: 100,
                            child: Text(
                              ket.isEmpty ? '-' : ket,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            )),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TAB 3 — RECAP
// ════════════════════════════════════════════════════════════════
class _RecapTab extends StatelessWidget {
  const _RecapTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    if (provider.selectedSchedule == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Pilih jadwal di tab Attendance terlebih dahulu',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (provider.recapState == StudentLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.recapError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: Colors.red.shade400, size: 48),
            const SizedBox(height: 12),
            Text(provider.recapError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade600)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.loadAttendanceRecap(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (provider.attendanceRecap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Belum ada data rekap',
                style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => provider.loadAttendanceRecap(),
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Rekap'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => provider.loadAttendanceRecap(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh Rekap'),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                          width: 32,
                          child: Text('No',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text('Nama',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 36,
                          child: Text('H',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 36,
                          child: Text('I',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 36,
                          child: Text('S',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 36,
                          child: Text('A',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 36,
                          child: Text('T',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ...provider.attendanceRecap.asMap().entries.map((e) {
                  final i = e.key;
                  final r = e.value;
                  final studentId = r['siswa_id'].toString();
                  final student = provider.studentList.firstWhere(
                        (s) => s['id'].toString() == studentId,
                    orElse: () =>
                    {'nama_lengkap': 'Siswa $studentId'},
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    color: i % 2 == 0
                        ? Colors.white
                        : Colors.grey.shade50,
                    child: Row(
                      children: [
                        SizedBox(
                            width: 32,
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey))),
                        Expanded(
                            child: Text(
                                student['nama_lengkap']?.toString() ??
                                    '-',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis)),
                        _RekapCell(
                            value: r['hadir'],
                            color: Colors.green.shade700),
                        _RekapCell(
                            value: r['izin'],
                            color: Colors.blue.shade700),
                        _RekapCell(
                            value: r['sakit'],
                            color: Colors.orange.shade700),
                        _RekapCell(
                            value: r['alpa'],
                            color: Colors.red.shade700),
                        _RekapCell(
                            value: r['terlambat'],
                            color: Colors.purple.shade700),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(label: 'H = Hadir', color: Colors.green),
              SizedBox(width: 12),
              _LegendItem(label: 'I = Izin', color: Colors.blue),
              SizedBox(width: 12),
              _LegendItem(label: 'S = Sakit', color: Colors.orange),
              SizedBox(width: 12),
              _LegendItem(label: 'A = Alpa', color: Colors.red),
              SizedBox(width: 12),
              _LegendItem(label: 'T = Terlambat', color: Colors.purple),
            ],
          ),
        ],
      ),
    );
  }
}

class _RekapCell extends StatelessWidget {
  final dynamic value;
  final Color color;
  const _RekapCell({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        value?.toString() ?? '0',
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _config = {
    'hadir': {
      'label': 'Hadir',
      'bg': Color(0xFFDCFCE7),
      'text': Color(0xFF166534)
    },
    'izin': {
      'label': 'Izin',
      'bg': Color(0xFFDBEAFE),
      'text': Color(0xFF1E40AF)
    },
    'sakit': {
      'label': 'Sakit',
      'bg': Color(0xFFFEF3C7),
      'text': Color(0xFF92400E)
    },
    'alpa': {
      'label': 'Alpa',
      'bg': Color(0xFFFEE2E2),
      'text': Color(0xFF991B1B)
    },
    'terlambat': {
      'label': 'Terlambat',
      'bg': Color(0xFFF3E8FF),
      'text': Color(0xFF6B21A8)
    },
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[status.toLowerCase()];
    if (cfg == null) {
      return Text(status, style: const TextStyle(fontSize: 11));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg['bg'] as Color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        cfg['label'] as String,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cfg['text'] as Color),
      ),
    );
  }
}