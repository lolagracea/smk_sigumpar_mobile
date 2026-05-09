import 'package:flutter/material.dart';
import 'dart:math' as math;

// ============================================================
// MODEL
// ============================================================
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

// ============================================================
// SCREEN
// ============================================================

// Nama class DIPERBAIKI: RekapKehadiranScreen → AttendanceRecapScreen
// agar sesuai dengan import di app_router.dart
class AttendanceRecapScreen extends StatefulWidget {
  const AttendanceRecapScreen({super.key});

  @override
  State<AttendanceRecapScreen> createState() => _AttendanceRecapScreenState();
}

class _AttendanceRecapScreenState extends State<AttendanceRecapScreen>
    with SingleTickerProviderStateMixin {
  // --------------- state ---------------
  String? _selectedKelas;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  bool _hasData = false;
  late AnimationController _animController;
  late Animation<double> _animProgress;

  final List<String> _kelasList = [
    'X TKJ 1', 'X TKJ 2', 'X RPL 1', 'X RPL 2',
    'XI TKJ 1', 'XI TKJ 2', 'XI RPL 1', 'XI RPL 2',
    'XII TKJ 1', 'XII TKJ 2', 'XII RPL 1', 'XII RPL 2',
  ];

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _tampilkanGrafik() {
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
    _animController.reset();

    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _isLoading = false;
        _hasData = true;
        _kehadiranData = [
          KehadiranData(label: 'Hadir', jumlah: 18, color: const Color(0xFF3182CE)),
          KehadiranData(label: 'Sakit', jumlah: 4,  color: const Color(0xFF38A169)),
          KehadiranData(label: 'Izin',  jumlah: 3,  color: const Color(0xFFD69E2E)),
          KehadiranData(label: 'Alpha', jumlah: 5,  color: const Color(0xFFE53E3E)),
        ];
      });
      _animController.forward();
    });
  }

  String _bulanLabel(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickMonth() async {
    await showDialog(
      context: context,
      builder: (ctx) => _MonthPickerDialog(
        initial: _selectedMonth,
        onSelected: (dt) {
          setState(() {
            _selectedMonth = dt;
            _hasData = false;
          });
        },
      ),
    );
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
            // ---- Header card ----
            _HeaderCard(
              title: 'ANALITIK KEHADIRAN SISWA',
              subtitle: 'Monitoring visual diagram lingkaran kehadiran kelas.',
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFF3182CE),
            ),
            const SizedBox(height: 16),

            // ---- Filter card ----
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pilih Kelas
                    const Text(
                      'PILIH KELAS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF718096),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E0)),
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFFF7FAFC),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedKelas,
                          hint: const Text(
                            '-- Pilih Kelas --',
                            style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Color(0xFF718096)),
                          items: _kelasList
                              .map((k) => DropdownMenuItem(
                            value: k,
                            child: Text(k,
                                style: const TextStyle(fontSize: 14)),
                          ))
                              .toList(),
                          onChanged: (val) => setState(() {
                            _selectedKelas = val;
                            _hasData = false;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pilih Bulan
                    const Text(
                      'PILIH BULAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF718096),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickMonth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E0)),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF7FAFC),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 16, color: Color(0xFF718096)),
                            const SizedBox(width: 8),
                            Text(
                              _bulanLabel(_selectedMonth),
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF2D3748)),
                            ),
                            const Spacer(),
                            const Icon(Icons.keyboard_arrow_down,
                                color: Color(0xFF718096)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _tampilkanGrafik,
                      icon: _isLoading
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.bar_chart, size: 18),
                      label: Text(_isLoading ? 'Memuat...' : 'TAMPILKAN GRAFIK'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3182CE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.5),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Chart area ----
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _hasData
                    ? AnimatedBuilder(
                  animation: _animProgress,
                  builder: (_, __) => _ChartContent(
                    data: _kehadiranData,
                    progress: _animProgress.value,
                    kelas: _selectedKelas!,
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

// ============================================================
// CHART CONTENT WIDGET
// ============================================================
class _ChartContent extends StatelessWidget {
  final List<KehadiranData> data;
  final double progress;
  final String kelas;
  final String bulan;

  const _ChartContent({
    required this.data,
    required this.progress,
    required this.kelas,
    required this.bulan,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (s, d) => s + d.jumlah);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pie_chart, color: Color(0xFF3182CE), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Kehadiran $kelas — $bulan',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Pie chart
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _PieChartPainter(
                  data: data, progress: progress, total: total),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const Text(
                      'Total Hari',
                      style: TextStyle(fontSize: 11, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Legend + stats
        ...data.map((d) {
          final pct =
          total > 0 ? (d.jumlah / total * 100).toStringAsFixed(1) : '0.0';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                      color: d.color,
                      borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(d.label,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF4A5568))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: d.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${d.jumlah} hari',
                    style: TextStyle(
                        fontSize: 12,
                        color: d.color,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text(
                    '$pct%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                        fontWeight: FontWeight.w600),
                  ),
                ),
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

  _PieChartPainter(
      {required this.data, required this.progress, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final innerRadius = radius * 0.55;

    var startAngle = -math.pi / 2;

    for (final d in data) {
      final sweepAngle = (d.jumlah / total) * 2 * math.pi * progress;
      final paint = Paint()
        ..color = d.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    // Donut hole
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PieChartPainter old) => old.progress != progress;
}

// ============================================================
// EMPTY STATE
// ============================================================
class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'SILAKAN PILIH FILTER\nUNTUK MELIHAT DIAGRAM LINGKARAN.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFA0AEC0),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HEADER CARD
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
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D3748),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF718096)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MONTH PICKER DIALOG
// ============================================================
class _MonthPickerDialog extends StatefulWidget {
  final DateTime initial;
  final ValueChanged<DateTime> onSelected;

  const _MonthPickerDialog(
      {required this.initial, required this.onSelected});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;
  late int _month;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _year--),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: Text(
              '$_year',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _year++),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      content: SizedBox(
        width: 240,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 12,
          itemBuilder: (_, i) {
            final selected = (i + 1) == _month;
            return GestureDetector(
              onTap: () {
                setState(() => _month = i + 1);
                widget.onSelected(DateTime(_year, i + 1));
                Navigator.pop(context);
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF3182CE)
                      : const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF3182CE)
                        : const Color(0xFFCBD5E0),
                  ),
                ),
                child: Text(
                  _months[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF4A5568),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}