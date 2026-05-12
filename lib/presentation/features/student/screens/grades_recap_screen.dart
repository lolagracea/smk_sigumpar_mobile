import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../data/repositories/student_repository.dart';
import '../providers/student_provider.dart';

// ─── Entry point (dipanggil dari router) ─────────────────────────
class GradesRecapScreen extends StatelessWidget {
  const GradesRecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentProvider(repository: sl<StudentRepository>())
        ..loadAssignments(),
      child: const _GradesView(),
    );
  }
}

// ─── Main View ───────────────────────────────────────────────────
class _GradesView extends StatefulWidget {
  const _GradesView();

  @override
  State<_GradesView> createState() => _GradesViewState();
}

class _GradesViewState extends State<_GradesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F7FA),
      child: Column(
        children: [
          _buildTabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _InputNilaiTab(),
                _RekapNilaiTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
        indicatorColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.edit_note_outlined), text: 'Input Nilai'),
          Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Rekap'),
        ],
      ),
    );
  }
}

// ─── Tab 1: Input Nilai ──────────────────────────────────────────
class _InputNilaiTab extends StatelessWidget {
  const _InputNilaiTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final hasAssignment = provider.selectedAssignment != null;
    final hasStudents = provider.nilaiStudents.isNotEmpty;

    return Column(
      children: [
        _FilterSection(),
        if (hasAssignment) _BobotSection(),
        Expanded(child: _StudentGradesList()),
        if (hasAssignment && hasStudents) const _SaveButton(),
      ],
    );
  }
}

// ─── Filter Section ──────────────────────────────────────────────
class _FilterSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<StudentProvider>();

    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<Map<String, dynamic>>(
            value: provider.selectedAssignment,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: 'Mapel & Kelas',
              labelStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade600),
              prefixIcon: Icon(Icons.menu_book_outlined,
                  color: isDark ? Colors.white54 : Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            hint: Text('Pilih Mapel & Kelas',
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey.shade600)),
            isExpanded: true,
            items: provider.assignments.map((a) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: a,
                child: Text(
                  '${a['nama_mapel'] ?? '-'} — ${a['nama_kelas'] ?? '-'}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: provider.assignmentState == StudentLoadState.loading
                ? null
                : (val) {
              if (val != null) provider.selectAssignment(val);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: provider.nilaiSemester,
                  dropdownColor:
                  isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Semester',
                    labelStyle: TextStyle(
                        color:
                        isDark ? Colors.white54 : Colors.grey.shade600),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color:
                          isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ganjil', child: Text('Ganjil')),
                    DropdownMenuItem(value: 'genap', child: Text('Genap')),
                  ],
                  onChanged: (val) {
                    if (val != null) provider.setNilaiSemester(val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: provider.tahunAjar,
                  dropdownColor:
                  isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tahun Ajar',
                    labelStyle: TextStyle(
                        color:
                        isDark ? Colors.white54 : Colors.grey.shade600),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color:
                          isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  items: ['2023/2024', '2024/2025', '2025/2026']
                      .map((y) =>
                      DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) provider.setTahunAjar(val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bobot Section ───────────────────────────────────────────────
class _BobotSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<StudentProvider>();
    final total = provider.totalBobot;
    final isValid = total == 100;

    final bgColor = isValid
        ? (isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.shade50)
        : (isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50);
    final borderColor = isValid
        ? (isDark ? Colors.amber.shade800 : Colors.amber.shade300)
        : (isDark ? Colors.red.shade800 : Colors.red.shade300);
    final headColor = isValid
        ? (isDark ? Colors.amber.shade300 : Colors.amber.shade800)
        : (isDark ? Colors.red.shade300 : Colors.red.shade700);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_outlined, size: 16, color: headColor),
              const SizedBox(width: 6),
              Text(
                'Bobot Nilai  (Total: $total%)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: headColor,
                ),
              ),
              if (!isValid) ...[
                const SizedBox(width: 8),
                Text('Harus 100%',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.red.shade300
                            : Colors.red.shade700)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BobotField(label: 'Tugas', key_: 'tugas'),
              const SizedBox(width: 8),
              _BobotField(label: 'Kuis', key_: 'kuis'),
              const SizedBox(width: 8),
              _BobotField(label: 'UTS', key_: 'uts'),
              const SizedBox(width: 8),
              _BobotField(label: 'UAS', key_: 'uas'),
              const SizedBox(width: 8),
              _BobotField(label: 'Praktik', key_: 'praktik'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BobotField extends StatefulWidget {
  final String label;
  final String key_;
  const _BobotField({required this.label, required this.key_});

  @override
  State<_BobotField> createState() => _BobotFieldState();
}

class _BobotFieldState extends State<_BobotField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final provider = context.read<StudentProvider>();
    _ctrl =
        TextEditingController(text: provider.bobot[widget.key_].toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Text(widget.label,
              style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 4),
          TextField(
            controller: _ctrl,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _MaxValueFormatter(100),
            ],
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              suffixText: '%',
              suffixStyle: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black87),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              isDense: true,
            ),
            onChanged: (val) {
              final v = int.tryParse(val) ?? 0;
              context.read<StudentProvider>().setBobot(widget.key_, v);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Student Grades List ─────────────────────────────────────────
class _StudentGradesList extends StatelessWidget {
  const _StudentGradesList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<StudentProvider>();

    if (provider.selectedAssignment == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined,
                size: 64,
                color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Pilih mapel & kelas untuk mulai input nilai',
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                    fontSize: 14)),
          ],
        ),
      );
    }

    if (provider.nilaiState == StudentLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.nilaiError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color:
                isDark ? Colors.red.shade300 : Colors.red.shade400,
                size: 48),
            const SizedBox(height: 12),
            Text(provider.nilaiError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark
                        ? Colors.red.shade300
                        : Colors.red.shade600)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: () => provider.reloadNilai(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (provider.nilaiStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 64,
                color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Tidak ada siswa di kelas ini',
                style: TextStyle(
                    color: isDark
                        ? Colors.white54
                        : Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
          child: Row(
            children: [
              Icon(Icons.people_outline,
                  size: 16,
                  color: isDark ? Colors.white54 : Colors.grey),
              const SizedBox(width: 6),
              Text('${provider.nilaiStudents.length} siswa',
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                provider.selectedAssignment?['nama_mapel'] ?? '',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB)),
              ),
            ],
          ),
        ),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color:
          isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
          child: Row(
            children: const [
              SizedBox(
                  width: 28,
                  child: Text('No',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600))),
              Expanded(
                  child: Text('Nama Siswa',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600))),
              _ColHeader('Tugas'),
              _ColHeader('Kuis'),
              _ColHeader('UTS'),
              _ColHeader('UAS'),
              _ColHeader('Praktik'),
              SizedBox(
                  width: 52,
                  child: Text('Akhir',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: provider.nilaiStudents.length,
            itemBuilder: (context, index) {
              final siswa = provider.nilaiStudents[index];
              return _StudentGradeRow(index: index, siswa: siswa);
            },
          ),
        ),
      ],
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String label;
  const _ColHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _StudentGradeRow extends StatefulWidget {
  final int index;
  final Map<String, dynamic> siswa;
  const _StudentGradeRow({required this.index, required this.siswa});

  @override
  State<_StudentGradeRow> createState() => _StudentGradeRowState();
}

class _StudentGradeRowState extends State<_StudentGradeRow> {
  late final Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    final provider = context.read<StudentProvider>();
    final id = widget.siswa['id'].toString();
    final existing = provider.gradeMap[id];

    _ctrls = {
      for (final k in ['tugas', 'kuis', 'uts', 'uas', 'praktik'])
        k: TextEditingController(
            text: (existing?[k] ?? 0).toStringAsFixed(0)),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<StudentProvider>();
    final id = widget.siswa['id'].toString();
    final akhir = provider.hitungNilaiAkhir(id);
    final isEven = widget.index % 2 == 0;

    final rowColor = isDark
        ? (isEven ? const Color(0xFF1E293B) : const Color(0xFF0F172A))
        : (isEven ? Colors.white : Colors.grey.shade50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: rowColor,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${widget.index + 1}',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.siswa['nama_lengkap']?.toString() ?? '-',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.siswa['nisn'] != null)
                  Text('NIS: ${widget.siswa['nisn']}',
                      style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.grey)),
              ],
            ),
          ),
          for (final key in ['tugas', 'kuis', 'uts', 'uas', 'praktik'])
            SizedBox(
              width: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: TextField(
                  controller: _ctrls[key],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _MaxValueFormatter(100),
                  ],
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor:
                    isDark ? const Color(0xFF334155) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 6),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final v = double.tryParse(val) ?? 0;
                    context
                        .read<StudentProvider>()
                        .updateGrade(id, key, v);
                    setState(() {});
                  },
                ),
              ),
            ),
          SizedBox(
            width: 52,
            child: Text(
              akhir.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: akhir >= 75
                    ? (isDark
                    ? Colors.green.shade300
                    : Colors.green.shade700)
                    : (isDark
                    ? Colors.red.shade300
                    : Colors.red.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<StudentProvider>();
    final canSave = provider.totalBobot == 100 && !provider.isSaving;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            disabledBackgroundColor:
            isDark ? Colors.white12 : Colors.grey.shade300,
            disabledForegroundColor:
            isDark ? Colors.white38 : Colors.grey.shade600,
          ),
          onPressed: canSave
              ? () async {
            final ok = await provider.saveNilai();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok
                  ? 'Nilai berhasil disimpan!'
                  : provider.nilaiError ?? 'Gagal menyimpan nilai'),
              backgroundColor: ok ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating,
            ));
          }
              : null,
          icon: provider.isSaving
              ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(
            provider.isSaving
                ? 'Menyimpan...'
                : provider.totalBobot != 100
                ? 'Bobot harus 100% (${provider.totalBobot}%)'
                : 'Simpan Semua Nilai',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

// ─── Tab 2: Rekap ────────────────────────────────────────────────
class _RekapNilaiTab extends StatelessWidget {
  const _RekapNilaiTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<StudentProvider>();

    if (provider.selectedAssignment == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Pilih mapel & kelas di tab Input Nilai terlebih dahulu',
            textAlign: TextAlign.center,
            style:
            TextStyle(color: isDark ? Colors.white54 : Colors.grey),
          ),
        ),
      );
    }

    if (provider.nilaiState == StudentLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.nilaiStudents.isEmpty) {
      return Center(
          child: Text('Belum ada data nilai',
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey)));
    }

    final nilaiList = provider.nilaiStudents
        .map((s) => provider.hitungNilaiAkhir(s['id'].toString()))
        .toList();
    final avg = nilaiList.isEmpty
        ? 0.0
        : nilaiList.reduce((a, b) => a + b) / nilaiList.length;
    final lulus = nilaiList.where((n) => n >= 75).length;
    final total = provider.nilaiStudents.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _StatCard(
                  label: 'Rata-rata',
                  value: avg.toStringAsFixed(1),
                  icon: Icons.assessment_outlined,
                  color: Colors.blue,
                  isDark: isDark),
              const SizedBox(width: 12),
              _StatCard(
                  label: 'Lulus ≥75',
                  value: '$lulus/$total',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  isDark: isDark),
              const SizedBox(width: 12),
              _StatCard(
                  label: 'Tidak Lulus',
                  value: '${total - lulus}/$total',
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  isDark: isDark),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.white12 : Colors.transparent),
              boxShadow: isDark
                  ? null
                  : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF2563EB),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(width: 32, child: Text('No', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Nama', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      SizedBox(width: 40, child: Text('Tgs', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      SizedBox(width: 40, child: Text('Kuis', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      SizedBox(width: 40, child: Text('UTS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      SizedBox(width: 40, child: Text('UAS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      SizedBox(width: 40, child: Text('Prk', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      SizedBox(width: 52, child: Text('Akhir', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ...provider.nilaiStudents.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  final id = s['id'].toString();
                  final g = provider.gradeMap[id];
                  final akhir = provider.hitungNilaiAkhir(id);
                  final lulus = akhir >= 75;

                  final rowColor = isDark
                      ? (i % 2 == 0
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF0F172A))
                      : (i % 2 == 0 ? Colors.white : Colors.grey.shade50);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    color: rowColor,
                    child: Row(
                      children: [
                        SizedBox(
                            width: 32,
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey))),
                        Expanded(
                            child: Text(
                                s['nama_lengkap']?.toString() ?? '-',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87),
                                overflow: TextOverflow.ellipsis)),
                        for (final k in ['tugas', 'kuis', 'uts', 'uas', 'praktik'])
                          SizedBox(
                              width: 40,
                              child: Text((g?[k] ?? 0).toStringAsFixed(0),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87))),
                        SizedBox(
                          width: 52,
                          child: Container(
                            margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: lulus
                                  ? (isDark
                                  ? Colors.green.withOpacity(0.25)
                                  : Colors.green.shade100)
                                  : (isDark
                                  ? Colors.red.withOpacity(0.25)
                                  : Colors.red.shade100),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              akhir.toStringAsFixed(1),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: lulus
                                    ? (isDark
                                    ? Colors.green.shade300
                                    : Colors.green.shade700)
                                    : (isDark
                                    ? Colors.red.shade300
                                    : Colors.red.shade700),
                              ),
                            ),
                          ),
                        ),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final MaterialColor color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
    isDark ? color.shade900.withOpacity(0.3) : color.shade50;
    final borderColor = isDark ? color.shade700 : color.shade200;
    final iconColor = isDark ? color.shade300 : color.shade600;
    final valueColor = isDark ? color.shade200 : color.shade700;
    final labelColor = isDark ? color.shade300 : color.shade600;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: valueColor)),
            Text(label,
                style: TextStyle(fontSize: 11, color: labelColor),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Input Formatter ─────────────────────────────────────────────
class _MaxValueFormatter extends TextInputFormatter {
  final int max;
  const _MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    if (newVal.text.isEmpty) return newVal;
    final v = int.tryParse(newVal.text);
    if (v == null || v > max) return old;
    return newVal;
  }
}