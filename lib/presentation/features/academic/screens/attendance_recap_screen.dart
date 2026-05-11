import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../academic/providers/academic_provider.dart';
import '../../student/providers/student_provider.dart';
import '../../../common/widgets/loading_widget.dart';

class KehadiranData {
  final String label;
  final int jumlah;
  final Color color;

  KehadiranData({
    required this.label,
    required this.jumlah,
    required this.color,
  });
}

class AttendanceRecapScreen extends StatefulWidget {
  const AttendanceRecapScreen({super.key});

  @override
  State<AttendanceRecapScreen> createState() => _AttendanceRecapScreenState();
}

class _AttendanceRecapScreenState extends State<AttendanceRecapScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedKelasId;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  bool _hasData = false;
  late AnimationController _animController;
  late Animation<double> _animProgress;

  List<KehadiranData> _kehadiranData = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animProgress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicProvider>().fetchClasses(refresh: true);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _tampilkanGrafik() async {
    if (_selectedKelasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kelas terlebih dahulu'),
          backgroundColor: Color(0xFFE53E3E),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    _animController.reset();

    try {
      final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      final provider = context.read<StudentProvider>();
      await provider.fetchAttendanceSummary(
        classId: _selectedKelasId!,
        tanggalMulai: DateFormat('yyyy-MM-dd').format(firstDay),
        tanggalAkhir: DateFormat('yyyy-MM-dd').format(lastDay),
      );

      final summaries = provider.summaries;
      
      int totalHadir = 0;
      int totalSakit = 0;
      int totalIzin = 0;
      int totalAlpa = 0;
      int totalTerlambat = 0; // Tambahkan variabel terlambat

      for (var s in summaries) {
        totalHadir += s.present;
        totalSakit += s.sick;
        totalIzin += s.permission;
        totalAlpa += s.absent;
        totalTerlambat += s.late; // Akumulasi data terlambat
      }

      setState(() {
        _isLoading = false;
        _hasData = true;
        _kehadiranData = [
          KehadiranData(label: 'Hadir', jumlah: totalHadir, color: const Color(0xFF3182CE)),
          KehadiranData(label: 'Sakit', jumlah: totalSakit,  color: const Color(0xFF38A169)),
          KehadiranData(label: 'Izin',  jumlah: totalIzin,  color: const Color(0xFFD69E2E)),
          KehadiranData(label: 'Alpha', jumlah: totalAlpa,  color: const Color(0xFFE53E3E)),
          KehadiranData(label: 'Terlambat', jumlah: totalTerlambat, color: Colors.purple), // Tambahkan ke data grafik
        ];
      });
      _animController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  String _bulanLabel(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _hasData = false;
      });
    }
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
          'Rekap Kehadiran',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(
              title: 'ANALITIK KEHADIRAN SISWA',
              subtitle: 'Monitoring visual diagram lingkaran kehadiran kelas.',
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFF3182CE),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('PILIH KELAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF718096), letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E0)),
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFFF7FAFC),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: Consumer<AcademicProvider>(
                          builder: (context, academic, child) {
                            return DropdownButton<String>(
                              value: _selectedKelasId,
                              hint: const Text('-- Pilih Kelas --', style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14)),
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF718096)),
                              items: academic.classes.map((k) => DropdownMenuItem(
                                value: k.id,
                                child: Text(k.namaKelas, style: const TextStyle(fontSize: 14)),
                              )).toList(),
                              onChanged: (val) => setState(() {
                                _selectedKelasId = val;
                                _hasData = false;
                              }),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('PILIH BULAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF718096), letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickMonth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E0)),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF7FAFC),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF718096)),
                            const SizedBox(width: 8),
                            Text(_bulanLabel(_selectedMonth), style: const TextStyle(fontSize: 14, color: Color(0xFF2D3748))),
                            const Spacer(),
                            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF718096)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _tampilkanGrafik,
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bar_chart, size: 18),
                      label: Text(_isLoading ? 'Memuat...' : 'TAMPILKAN GRAFIK'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3182CE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _hasData
                    ? AnimatedBuilder(
                  animation: _animProgress,
                  builder: (_, __) => _ChartContent(
                    data: _kehadiranData,
                    progress: _animProgress.value,
                    bulan: _bulanLabel(_selectedMonth),
                  ),
                )
                    : _EmptyChart(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartContent extends StatelessWidget {
  final List<KehadiranData> data;
  final double progress;
  final String bulan;

  const _ChartContent({required this.data, required this.progress, required this.bulan});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (s, d) => s + d.jumlah);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Analitik Kehadiran — $bulan', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2D3748))),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _PieChartPainter(data: data, progress: progress, total: total),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$total', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF2D3748))),
                    const Text('Total Presensi', style: TextStyle(fontSize: 11, color: Color(0xFF718096))),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...data.map((d) {
          final pct = total > 0 ? (d.jumlah / total * 100).toStringAsFixed(1) : '0.0';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(width: 14, height: 14, decoration: BoxDecoration(color: d.color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 10),
                Expanded(child: Text(d.label, style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568)))),
                Text('${d.jumlah} ($pct%)', style: const TextStyle(fontSize: 12, color: Color(0xFF718096), fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<KehadiranData> data;
  final double progress;
  final int total;

  _PieChartPainter({required this.data, required this.progress, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    var startAngle = -math.pi / 2;

    for (final d in data) {
      final sweepAngle = (d.jumlah / total) * 2 * math.pi * progress;
      final paint = Paint()..color = d.color..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
    canvas.drawCircle(center, radius * 0.55, Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_PieChartPainter old) => old.progress != progress;
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 180, child: Center(child: Text('SILAKAN PILIH FILTER\nUNTUK MELIHAT DIAGRAM LINGKARAN.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFFA0AEC0), fontWeight: FontWeight.w600))));
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  const _HeaderCard({required this.title, required this.subtitle, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: iconColor, width: 4))),
      child: Row(children: [Icon(icon, color: iconColor, size: 28), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2D3748))), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF718096)))]))]),
    );
  }
}
