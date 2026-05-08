import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';

class KurikulumScreen extends StatefulWidget {
  const KurikulumScreen({super.key});

  @override
  State<KurikulumScreen> createState() => _KurikulumScreenState();
}

class _KurikulumScreenState extends State<KurikulumScreen> {
  List<Map<String, dynamic>> _kelas  = [];
  List<Map<String, dynamic>> _mapel  = [];
  List<Map<String, dynamic>> _jadwal = [];

  bool    _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── API: sama persis web — getAllKelas + getAllMapel + getAllJadwal ──────────
  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = sl<DioClient>();
      final results = await Future.wait([
        dio.get(ApiEndpoints.classes),
        dio.get(ApiEndpoints.subjects),
        dio.get(ApiEndpoints.schedules),
      ]);

      List<Map<String, dynamic>> parse(dynamic raw) {
        final list = raw is List
            ? raw
            : (raw is Map ? (raw['data'] ?? []) : []);
        return List<Map<String, dynamic>>.from(list as List);
      }

      setState(() {
        _kelas  = parse(results[0].data);
        _mapel  = parse(results[1].data);
        _jadwal = parse(results[2].data);
      });
    } catch (_) {
      setState(() => _error = 'Gagal memuat data kurikulum');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _namaKelas(dynamic kelasId) {
    if (kelasId == null) return '—';
    final found = _kelas.where((k) => k['id'] == kelasId);
    return found.isNotEmpty ? (found.first['nama_kelas'] ?? '—') : '—';
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF0F1117) : const Color(0xFFF3F4F6);
    final card    = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final border  = isDark ? const Color(0xFF2D3142) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('KURIKULUM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              )),
          Text('Rekap data kurikulum — kelas, mata pelajaran, dan jadwal mengajar',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              )),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [

                      // ── 3 Stat Card ──────────────────────────────────────
                      Row(children: [
                        _StatCard(
                          label: 'Total Kelas',
                          value: _kelas.length,
                          icon: '🏫',
                          bgColor:     isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                          borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                          valueColor:  const Color(0xFF2563EB),
                          labelColor:  const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Mata Pelajaran',
                          value: _mapel.length,
                          icon: '📚',
                          bgColor:     isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4),
                          borderColor: isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0),
                          valueColor:  const Color(0xFF16A34A),
                          labelColor:  const Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Jadwal Mengajar',
                          value: _jadwal.length,
                          icon: '📅',
                          bgColor:     isDark ? const Color(0xFF2E1065) : const Color(0xFFFAF5FF),
                          borderColor: isDark ? const Color(0xFF6B21A8) : const Color(0xFFE9D5FF),
                          valueColor:  const Color(0xFF7C3AED),
                          labelColor:  const Color(0xFFA855F7),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── Tabel Daftar Kelas ────────────────────────────────
                      _TableCard(
                        title: 'Daftar Kelas',
                        isDark: isDark,
                        card: card,
                        border: border,
                        headers: const ['NO', 'NAMA KELAS', 'TINGKAT'],
                        flexes:  const [1, 3, 2],
                        emptyMsg: 'Belum ada data kelas',
                        boldCol: 1,
                        rows: List.generate(_kelas.length, (i) {
                          final k = _kelas[i];
                          return [
                            '${i + 1}',
                            k['nama_kelas'] ?? '—',
                            'Kelas ${k['tingkat'] ?? '—'}',
                          ];
                        }),
                      ),
                      const SizedBox(height: 16),

                      // ── Tabel Daftar Mata Pelajaran ───────────────────────
                      _TableCard(
                        title: 'Daftar Mata Pelajaran',
                        isDark: isDark,
                        card: card,
                        border: border,
                        headers: const ['NO', 'NAMA MAPEL', 'KELAS'],
                        flexes:  const [1, 3, 2],
                        emptyMsg: 'Belum ada data mata pelajaran',
                        boldCol: 1,
                        rows: List.generate(_mapel.length, (i) {
                          final m = _mapel[i];
                          return [
                            '${i + 1}',
                            m['nama_mapel'] ?? '—',
                            _namaKelas(m['kelas_id']),
                          ];
                        }),
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int    value;
  final String icon;
  final Color  bgColor;
  final Color  borderColor;
  final Color  valueColor;
  final Color  labelColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text('$value',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: valueColor)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: labelColor)),
          ]),
        ),
      );
}

// ─── Table Card ───────────────────────────────────────────────────────────────

class _TableCard extends StatelessWidget {
  final String         title;
  final bool           isDark;
  final Color          card;
  final Color          border;
  final List<String>   headers;
  final List<int>      flexes;
  final String         emptyMsg;
  final List<List<String>> rows;
  final int            boldCol;

  const _TableCard({
    required this.title,
    required this.isDark,
    required this.card,
    required this.border,
    required this.headers,
    required this.flexes,
    required this.emptyMsg,
    required this.rows,
    this.boldCol = -1,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary   = isDark ? Colors.white   : const Color(0xFF1F2937);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final headerBg      = isDark ? const Color(0xFF252836) : const Color(0xFFF9FAFB);
    final dividerColor  = isDark ? const Color(0xFF2D3142) : const Color(0xFFF3F4F6);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Judul tabel
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary)),
        ),
        Divider(height: 1, color: border),

        // Header kolom
        Container(
          color: headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: List.generate(
              headers.length,
              (i) => Expanded(
                flex: flexes[i],
                child: Text(headers[i],
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: textSecondary)),
              ),
            ),
          ),
        ),
        Divider(height: 1, color: border),

        // Data rows / empty state
        rows.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                    child: Text(emptyMsg,
                        style: TextStyle(color: textSecondary, fontSize: 13))),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: dividerColor),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: List.generate(
                      rows[i].length,
                      (j) => Expanded(
                        flex: flexes[j],
                        child: Text(
                          rows[i][j],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: j == boldCol
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: j == 0
                                ? textSecondary
                                : j == boldCol
                                    ? textPrimary
                                    : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ]),
    );
  }
}