import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../academic/providers/academic_provider.dart';
import '../providers/student_provider.dart';

class GradesViewScreen extends StatefulWidget {
  const GradesViewScreen({super.key});

  @override
  State<GradesViewScreen> createState() => _GradesViewScreenState();
}

class _GradesViewScreenState extends State<GradesViewScreen> {
  String? _selectedClassId;
  String _semester = 'ganjil';
  String _tahunAjar = '2024/2025';

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
    context.read<StudentProvider>().fetchGrades(
      classId: _selectedClassId!,
      semester: _semester,
      academicYear: _tahunAjar,
    );
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
                    child: DropdownButtonFormField<String>(
                      value: _semester,
                      dropdownColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Semester',
                        labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600),
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
                      items: const [
                        DropdownMenuItem(
                            value: 'ganjil', child: Text('Ganjil')),
                        DropdownMenuItem(
                            value: 'genap', child: Text('Genap')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _semester = val);
                          _fetchData();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _tahunAjar,
                      dropdownColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Tahun Ajar',
                        labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600),
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
                      items: ['2023/2024', '2024/2025', '2025/2026']
                          .map((y) =>
                          DropdownMenuItem(value: y, child: Text(y)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _tahunAjar = val);
                          _fetchData();
                        }
                      },
                    ),
                  ),
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
              if (provider.gradeState == StudentLoadState.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              // ── Error State ──────────────────────────────
              if (provider.gradeState == StudentLoadState.error) {
                final errorMsg = provider.gradeError;
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
                      : 'Terjadi kesalahan saat memuat data nilai.';
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
              if (provider.grades.isEmpty) {
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
                            Icons.assessment_outlined,
                            size: 52,
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Belum Ada Data Nilai',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color:
                            isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Data nilai untuk kelas ini, semester $_semester, '
                              'tahun ajaran $_tahunAjar belum tersedia.\n'
                              'Pastikan kelas ini adalah kelas yang Anda ampu sebagai wali kelas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                          ),
                        ),
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
                    _buildStatRow(provider, isDark),
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
                              child: Text('No', style: _hStyle)),
                          Expanded(
                              child: Text('Nama Siswa', style: _hStyle)),
                          SizedBox(
                              width: 60,
                              child: Text('Mapel',
                                  textAlign: TextAlign.center,
                                  style: _hStyle)),
                          SizedBox(
                              width: 52,
                              child: Text('Nilai',
                                  textAlign: TextAlign.center,
                                  style: _hStyle)),
                          SizedBox(
                              width: 52,
                              child: Text('Grade',
                                  textAlign: TextAlign.center,
                                  style: _hStyle)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: provider.grades.length,
                        itemBuilder: (context, index) {
                          final g = provider.grades[index];
                          final isEven = index % 2 == 0;
                          final rowColor = isDark
                              ? (isEven
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF0F172A))
                              : (isEven
                              ? Colors.white
                              : Colors.grey.shade50);

                          final nilaiAkhir = g.nilaiAkhir;
                          final lulus = nilaiAkhir >= 75;
                          final grade = g.letterGrade;

                          return Container(
                            color: rowColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
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
                                        g.studentName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (g.nisn != null)
                                        Text(
                                          'NISN: ${g.nisn}',
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
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    g.subjectId,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 52,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: lulus
                                          ? (isDark
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.green.shade50)
                                          : (isDark
                                          ? Colors.red.withOpacity(0.2)
                                          : Colors.red.shade50),
                                      borderRadius:
                                      BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      nilaiAkhir.toStringAsFixed(1),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
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
                                SizedBox(
                                  width: 52,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _gradeColor(grade, isDark),
                                        borderRadius:
                                        BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        grade,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
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

  Widget _buildStatRow(StudentProvider provider, bool isDark) {
    final grades = provider.grades;
    final total = grades.length;
    final lulus = grades.where((g) => g.nilaiAkhir >= 75).length;
    final avgNilai = total == 0
        ? 0.0
        : grades.fold<double>(0, (sum, g) => sum + g.nilaiAkhir) / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
      child: Row(
        children: [
          _MiniStat(
              label: 'Total Siswa',
              value: '$total',
              color: Colors.blue,
              isDark: isDark),
          const SizedBox(width: 8),
          _MiniStat(
              label: 'Lulus ≥75',
              value: '$lulus',
              color: Colors.green,
              isDark: isDark),
          const SizedBox(width: 8),
          _MiniStat(
              label: 'Tidak Lulus',
              value: '${total - lulus}',
              color: Colors.red,
              isDark: isDark),
          const SizedBox(width: 8),
          _MiniStat(
              label: 'Rata-rata',
              value: avgNilai.toStringAsFixed(1),
              color: Colors.purple,
              isDark: isDark),
        ],
      ),
    );
  }

  Color _gradeColor(String grade, bool isDark) {
    switch (grade) {
      case 'A':
        return isDark ? Colors.green.shade700 : Colors.green.shade600;
      case 'B':
        return isDark ? Colors.blue.shade700 : Colors.blue.shade600;
      case 'C':
        return isDark ? Colors.orange.shade700 : Colors.orange.shade600;
      case 'D':
        return isDark
            ? Colors.deepOrange.shade700
            : Colors.deepOrange.shade600;
      default:
        return isDark ? Colors.red.shade700 : Colors.red.shade600;
    }
  }
}

const _hStyle = TextStyle(
  color: Colors.white,
  fontSize: 11,
  fontWeight: FontWeight.bold,
);

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final MaterialColor color;
  final bool isDark;
  const _MiniStat(
      {required this.label,
        required this.value,
        required this.color,
        required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.15) : color.shade50,
          borderRadius: BorderRadius.circular(8),
          border:
          Border.all(color: isDark ? color.shade800 : color.shade200),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? color.shade300 : color.shade700)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: isDark ? color.shade400 : color.shade600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}