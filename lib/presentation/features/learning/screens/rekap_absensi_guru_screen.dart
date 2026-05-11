import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

class _RekapAbsensiGuruRow {
  final String id;
  final String userId;
  final String namaGuru;
  final String mataPelajaran;
  final String tanggal;
  final String? jamMasuk;
  final String status;
  final String keterangan;
  final String? foto;

  const _RekapAbsensiGuruRow({
    required this.id,
    required this.userId,
    required this.namaGuru,
    required this.mataPelajaran,
    required this.tanggal,
    required this.jamMasuk,
    required this.status,
    required this.keterangan,
    required this.foto,
  });

  factory _RekapAbsensiGuruRow.fromJson(Map<String, dynamic> json) {
    return _RekapAbsensiGuruRow(
      id: (json['id_absensiGuru'] ??
          json['id_absensiguru'] ??
          json['id_absensi_guru'] ??
          json['id'] ??
          '')
          .toString(),
      userId: (json['user_id'] ?? '').toString(),
      namaGuru: (json['namaGuru'] ??
          json['nama_guru'] ??
          json['nama'] ??
          json['nama_lengkap'] ??
          '-')
          .toString(),
      mataPelajaran: (json['mataPelajaran'] ??
          json['mata_pelajaran'] ??
          json['mapel'] ??
          json['nama_mapel'] ??
          '-')
          .toString(),
      tanggal: _normalizeDate(json['tanggal']),
      jamMasuk: (json['jamMasuk'] ??
          json['jam_masuk'] ??
          json['jam_masuk_guru'])
          ?.toString(),
      status: (json['status'] ?? '-').toString().toLowerCase(),
      keterangan: (json['keterangan'] ?? '-').toString(),
      foto: (json['foto'] ??
          json['foto_url'] ??
          json['fotoAbsensi'] ??
          json['foto_absensi'])
          ?.toString(),
    );
  }

  static String _normalizeDate(dynamic value) {
    if (value == null) return '-';

    final raw = value.toString();

    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      return raw;
    }

    try {
      final parsed = DateTime.parse(raw);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return raw;
    }
  }
}

class RekapAbsensiGuruScreen extends StatefulWidget {
  const RekapAbsensiGuruScreen({super.key});

  @override
  State<RekapAbsensiGuruScreen> createState() =>
      _RekapAbsensiGuruScreenState();
}

class _RekapAbsensiGuruScreenState extends State<RekapAbsensiGuruScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<_RekapAbsensiGuruRow> _rows = [];
  bool _loading = false;
  String? _error;

  String _modeFilter = 'harian';
  String _tanggal = _todayStr();
  String _tanggalMulai = _todayStr();
  String _tanggalAkhir = _todayStr();
  String _status = '';
  String _search = '';

  static String _todayStr() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();

      final params = <String, dynamic>{};

      if (_modeFilter == 'harian') {
        params['tanggal'] = _tanggal;
      } else {
        params['tanggal_mulai'] = _tanggalMulai;
        params['tanggal_akhir'] = _tanggalAkhir;
      }

      if (_status.isNotEmpty) {
        params['status'] = _status;
      }

      final response = await dio.get(
        ApiEndpoints.teacherAttendance,
        queryParameters: params,
      );

      final raw = response.data;

      List<dynamic> list = [];

      if (raw is List) {
        list = raw;
      } else if (raw is Map) {
        list = raw['data'] is List ? raw['data'] as List : [];
      }

      setState(() {
        _rows = list
            .whereType<Map<String, dynamic>>()
            .map(_RekapAbsensiGuruRow.fromJson)
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat rekap absensi guru';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<_RekapAbsensiGuruRow> get _filteredRows {
    final keyword = _search.toLowerCase().trim();

    return _rows.where((row) {
      if (keyword.isNotEmpty) {
        final nama = row.namaGuru.toLowerCase();
        final mapel = row.mataPelajaran.toLowerCase();

        if (!nama.contains(keyword) && !mapel.contains(keyword)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int _countByStatus(String status) {
    return _filteredRows.where((row) => row.status == status).length;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return const Color(0xFF16A34A);
      case 'terlambat':
        return const Color(0xFFD97706);
      case 'izin':
        return const Color(0xFF2563EB);
      case 'sakit':
        return const Color(0xFFEA580C);
      case 'alpa':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return 'Hadir';
      case 'terlambat':
        return 'Terlambat';
      case 'izin':
        return 'Izin';
      case 'sakit':
        return 'Sakit';
      case 'alpa':
        return 'Alpa';
      default:
        return status;
    }
  }

  String _formatDateDisplay(String value) {
    try {
      final parsed = DateTime.parse(value);
      return DateFormat('dd MMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      return value;
    }
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '-';

    try {
      final parsed = DateTime.parse(value).toLocal();
      return '${DateFormat('HH:mm').format(parsed)} WIB';
    } catch (_) {
      return value.length >= 5 ? '${value.substring(0, 5)} WIB' : value;
    }
  }

  String? _fullPhotoUrl(String? foto) {
    if (foto == null || foto.isEmpty || foto == '-') return null;

    if (foto.startsWith('data:')) return foto;
    if (foto.startsWith('http')) return foto;

    return '${ApiEndpoints.baseUrl}$foto';
  }

  Future<void> _pickDate({
    required String currentValue,
    required void Function(String value) onPicked,
  }) async {
    DateTime initialDate;

    try {
      initialDate = DateTime.parse(currentValue);
    } catch (_) {
      initialDate = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    final formatted = DateFormat('yyyy-MM-dd').format(picked);

    setState(() {
      onPicked(formatted);
    });

    await _loadData();
  }

  void _resetFilter() {
    final today = _todayStr();

    setState(() {
      _modeFilter = 'harian';
      _tanggal = today;
      _tanggalMulai = today;
      _tanggalAkhir = today;
      _status = '';
      _search = '';
      _searchController.clear();
    });

    _loadData();
  }

  Future<void> _exportExcel() async {
    final rows = _filteredRows;

    if (rows.isEmpty) {
      _showSnack('Tidak ada data untuk diexport');
      return;
    }

    final excel = excel_pkg.Excel.createExcel();
    final sheet = excel['Rekap Absensi Guru'];

    sheet.appendRow([
      excel_pkg.TextCellValue('No'),
      excel_pkg.TextCellValue('Nama Guru'),
      excel_pkg.TextCellValue('Mata Pelajaran'),
      excel_pkg.TextCellValue('Tanggal'),
      excel_pkg.TextCellValue('Jam Masuk'),
      excel_pkg.TextCellValue('Status'),
      excel_pkg.TextCellValue('Keterangan'),
    ]);

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];

      sheet.appendRow([
        excel_pkg.IntCellValue(i + 1),
        excel_pkg.TextCellValue(row.namaGuru),
        excel_pkg.TextCellValue(row.mataPelajaran),
        excel_pkg.TextCellValue(row.tanggal),
        excel_pkg.TextCellValue(_formatTime(row.jamMasuk)),
        excel_pkg.TextCellValue(_statusLabel(row.status)),
        excel_pkg.TextCellValue(row.keterangan),
      ]);
    }

    final bytes = excel.encode();

    if (bytes == null) {
      _showSnack('Gagal membuat file Excel');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();

    final periode = _modeFilter == 'harian'
        ? _tanggal
        : '${_tanggalMulai}_sd_$_tanggalAkhir';

    final path = '${dir.path}/rekap-absensi-guru-$periode.xlsx';

    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    _showSnack('File Excel berhasil dibuat');
    await OpenFilex.open(path);
  }

  Future<void> _downloadPhoto(String foto) async {
    try {
      final Uint8List bytes;

      if (foto.startsWith('data:')) {
        final base64Part = foto.split(',').last;
        bytes = base64Decode(base64Part);
      } else {
        final response = await Dio().get<List<int>>(
          foto,
          options: Options(responseType: ResponseType.bytes),
        );

        bytes = Uint8List.fromList(response.data ?? []);
      }

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/foto-absensi-guru-${DateTime.now().millisecondsSinceEpoch}.jpg';

      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      _showSnack('Foto berhasil disimpan');
      await OpenFilex.open(path);
    } catch (e) {
      _showSnack('Gagal download foto');
    }
  }

  void _showPhotoPreview(String foto) {
    final fullFoto = _fullPhotoUrl(foto);

    if (fullFoto == null) {
      _showSnack('Foto tidak tersedia');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  color: const Color(0xFF2563EB),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Preview Foto Absensi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildImage(fullFoto, BoxFit.contain),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadPhoto(fullFoto),
                      icon: const Icon(Icons.download),
                      label: const Text('Download Foto'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage(String foto, BoxFit fit) {
    if (foto.startsWith('data:')) {
      try {
        final base64Part = foto.split(',').last;
        return Image.memory(
          base64Decode(base64Part),
          fit: fit,
          errorBuilder: (_, __, ___) {
            return const Center(child: Text('Gagal memuat foto'));
          },
        );
      } catch (_) {
        return const Center(child: Text('Format foto tidak valid'));
      }
    }

    return Image.network(
      foto,
      fit: fit,
      errorBuilder: (_, __, ___) {
        return const Center(child: Text('Gagal memuat foto'));
      },
    );
  }

  Widget _buildThumbnail(String? foto) {
    final fullFoto = _fullPhotoUrl(foto);

    if (fullFoto == null) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
        ),
      );
    }

    return InkWell(
      onTap: () => _showPhotoPreview(fullFoto),
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 52,
          height: 52,
          child: _buildImage(fullFoto, BoxFit.cover),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = _filteredRows;

    return Container(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F7FA),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsHeader(isDark),
            const SizedBox(height: 12),
            _buildFilterCard(isDark),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildError()
            else if (rows.isEmpty)
                _buildEmpty()
              else
                ...rows.map((row) => _buildRowCard(row, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekap Absensi Guru',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pantau absensi guru berdasarkan hari atau range tanggal.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(label: 'Total', value: '${_filteredRows.length}'),
              _StatChip(label: 'Hadir', value: '${_countByStatus('hadir')}'),
              _StatChip(
                label: 'Terlambat',
                value: '${_countByStatus('terlambat')}',
              ),
              _StatChip(label: 'Izin', value: '${_countByStatus('izin')}'),
              _StatChip(label: 'Sakit', value: '${_countByStatus('sakit')}'),
              _StatChip(label: 'Alpa', value: '${_countByStatus('alpa')}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _modeFilter,
            decoration: const InputDecoration(
              labelText: 'Mode Filter',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: 'harian',
                child: Text('Per Hari'),
              ),
              DropdownMenuItem(
                value: 'range',
                child: Text('Range Tanggal'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _modeFilter = value;
              });

              _loadData();
            },
          ),
          const SizedBox(height: 10),
          if (_modeFilter == 'harian')
            _DatePickerField(
              label: 'Tanggal',
              value: _tanggal,
              onTap: () {
                _pickDate(
                  currentValue: _tanggal,
                  onPicked: (value) => _tanggal = value,
                );
              },
            )
          else
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Tanggal Mulai',
                    value: _tanggalMulai,
                    onTap: () {
                      _pickDate(
                        currentValue: _tanggalMulai,
                        onPicked: (value) => _tanggalMulai = value,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DatePickerField(
                    label: 'Tanggal Akhir',
                    value: _tanggalAkhir,
                    onTap: () {
                      _pickDate(
                        currentValue: _tanggalAkhir,
                        onPicked: (value) => _tanggalAkhir = value,
                      );
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('Semua Status')),
              DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
              DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
              DropdownMenuItem(value: 'izin', child: Text('Izin')),
              DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
              DropdownMenuItem(value: 'alpa', child: Text('Alpa')),
            ],
            onChanged: (value) {
              setState(() {
                _status = value ?? '';
              });

              _loadData();
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Cari Guru / Mapel',
              hintText: 'Contoh: Budi / Matematika',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _search = value;
              });
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetFilter,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportExcel,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export Excel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowCard(_RekapAbsensiGuruRow row, bool isDark) {
    final statusColor = _statusColor(row.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          _buildThumbnail(row.foto),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.namaGuru,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  row.mataPelajaran,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateDisplay(row.tanggal),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(row.jamMasuk),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                if (row.keterangan != '-' && row.keterangan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    row.keterangan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.45)),
            ),
            child: Text(
              _statusLabel(row.status),
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(_error ?? 'Gagal memuat data'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.fact_check_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Belum ada data absensi guru untuk filter ini',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  String _displayValue() {
    try {
      final parsed = DateTime.parse(value);
      return DateFormat('dd MMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          suffixIcon: Icon(Icons.calendar_today, size: 16),
        ).copyWith(labelText: label),
        child: Text(
          _displayValue(),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}