import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

class _EvaluationCriteria {
  final String id;
  final String label;
  final int weight;

  const _EvaluationCriteria({
    required this.id,
    required this.label,
    required this.weight,
  });
}

class _TeacherOption {
  final String id;
  final String nama;
  final String username;
  final String email;
  final String mapel;

  const _TeacherOption({
    required this.id,
    required this.nama,
    required this.username,
    required this.email,
    required this.mapel,
  });

  factory _TeacherOption.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['user_id'] ?? '').toString();

    return _TeacherOption(
      id: id,
      nama: (json['nama'] ??
          json['nama_lengkap'] ??
          json['nama_guru'] ??
          json['username'] ??
          '-')
          .toString(),
      username: (json['username'] ?? '-').toString(),
      email: (json['email'] ?? '-').toString(),
      mapel: (json['mapel'] ??
          json['mata_pelajaran'] ??
          json['nama_mapel'] ??
          '-')
          .toString(),
    );
  }
}

class _EvaluationHistory {
  final String id;
  final String guruId;
  final String namaGuru;
  final String mapel;
  final String semester;
  final Map<String, dynamic> penilaian;
  final double skor;
  final String predikat;
  final String catatan;
  final String evaluatorNama;
  final String evaluatorRole;
  final DateTime? createdAt;

  const _EvaluationHistory({
    required this.id,
    required this.guruId,
    required this.namaGuru,
    required this.mapel,
    required this.semester,
    required this.penilaian,
    required this.skor,
    required this.predikat,
    required this.catatan,
    required this.evaluatorNama,
    required this.evaluatorRole,
    required this.createdAt,
  });

  factory _EvaluationHistory.fromJson(Map<String, dynamic> json) {
    return _EvaluationHistory(
      id: (json['id'] ?? '').toString(),
      guruId: (json['guru_id'] ?? '').toString(),
      namaGuru: (json['nama_guru'] ??
          json['namaGuru'] ??
          json['nama'] ??
          '-')
          .toString(),
      mapel: (json['mapel'] ?? json['mata_pelajaran'] ?? '-').toString(),
      semester: (json['semester'] ?? '-').toString(),
      penilaian: _parsePenilaian(json['penilaian']),
      skor: _toDouble(json['skor'] ?? json['total']),
      predikat: (json['predikat'] ?? '').toString(),
      catatan: (json['catatan'] ?? '-').toString(),
      evaluatorNama:
      (json['evaluator_nama'] ?? json['evaluatorNama'] ?? '-').toString(),
      evaluatorRole:
      (json['evaluator_role'] ?? json['evaluatorRole'] ?? '-').toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  static Map<String, dynamic> _parsePenilaian(dynamic raw) {
    if (raw == null) return {};

    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return {};
      }
    }

    return {};
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }
}

class TeacherEvaluationScreen extends StatefulWidget {
  const TeacherEvaluationScreen({super.key});

  @override
  State<TeacherEvaluationScreen> createState() =>
      _TeacherEvaluationScreenState();
}

class _TeacherEvaluationScreenState extends State<TeacherEvaluationScreen> {
  static const List<_EvaluationCriteria> _criteria = [
    _EvaluationCriteria(
      id: 'perencanaan',
      label: 'Perencanaan Pembelajaran',
      weight: 20,
    ),
    _EvaluationCriteria(
      id: 'pelaksanaan',
      label: 'Pelaksanaan Pembelajaran',
      weight: 30,
    ),
    _EvaluationCriteria(
      id: 'penilaian',
      label: 'Penilaian Hasil Belajar',
      weight: 20,
    ),
    _EvaluationCriteria(
      id: 'pengembangan',
      label: 'Pengembangan Profesional',
      weight: 15,
    ),
    _EvaluationCriteria(
      id: 'disiplin',
      label: 'Kedisiplinan',
      weight: 15,
    ),
  ];

  final TextEditingController _catatanController = TextEditingController();
  final Map<String, TextEditingController> _scoreControllers = {
    for (final item in _criteria) item.id: TextEditingController(),
  };

  bool _loadingGuru = false;
  bool _loadingHistory = false;
  bool _saving = false;

  String? _error;
  String? _selectedTeacherId;

  List<_TeacherOption> _teachers = [];
  List<_EvaluationHistory> _histories = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _catatanController.dispose();

    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  _TeacherOption? get _selectedTeacher {
    for (final teacher in _teachers) {
      if (teacher.id == _selectedTeacherId) {
        return teacher;
      }
    }

    return null;
  }

  double _scoreOf(String key) {
    final raw = _scoreControllers[key]?.text.trim() ?? '';
    if (raw.isEmpty) return 0;
    return double.tryParse(raw.replaceAll(',', '.')) ?? 0;
  }

  Map<String, double> get _penilaian {
    return {
      for (final item in _criteria) item.id: _scoreOf(item.id),
    };
  }

  double get _finalScore {
    double total = 0;

    for (final item in _criteria) {
      total += (_scoreOf(item.id) * item.weight) / 100;
    }

    return double.parse(total.toStringAsFixed(1));
  }

  String _predicateOf(double value) {
    if (value >= 90) return 'Sangat Baik';
    if (value >= 75) return 'Baik';
    if (value >= 60) return 'Cukup';
    return 'Perlu Peningkatan';
  }

  Color _colorOf(double value) {
    if (value >= 90) return const Color(0xFF16A34A);
    if (value >= 75) return const Color(0xFF2563EB);
    if (value >= 60) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;

    if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) return raw['data'] as List;

      if (raw['data'] is Map<String, dynamic>) {
        final data = raw['data'] as Map<String, dynamic>;

        if (data['data'] is List) return data['data'] as List;
        if (data['items'] is List) return data['items'] as List;
        if (data['rows'] is List) return data['rows'] as List;
      }

      if (raw['items'] is List) return raw['items'] as List;
      if (raw['rows'] is List) return raw['rows'] as List;
    }

    return [];
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';

    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(value.toLocal());
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadTeachers(),
      _loadHistories(),
    ]);
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _loadingGuru = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();

      final response = await dio.get(ApiEndpoints.teacherEvaluationGuruMapel);
      final rows = _extractList(response.data);

      setState(() {
        _teachers = rows
            .whereType<Map>()
            .map((item) => _TeacherOption.fromJson(
          Map<String, dynamic>.from(item),
        ))
            .where((item) => item.id.isNotEmpty)
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = _messageFromError(
          e,
          fallback: 'Gagal mengambil data guru-mapel',
        );
        _teachers = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingGuru = false;
        });
      }
    }
  }

  Future<void> _loadHistories() async {
    setState(() {
      _loadingHistory = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();

      final response = await dio.get(ApiEndpoints.teacherEvaluation);
      final rows = _extractList(response.data);

      setState(() {
        _histories = rows
            .whereType<Map>()
            .map((item) => _EvaluationHistory.fromJson(
          Map<String, dynamic>.from(item),
        ))
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = _messageFromError(
          e,
          fallback: 'Gagal mengambil riwayat evaluasi',
        );
        _histories = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingHistory = false;
        });
      }
    }
  }

  String _messageFromError(
      Object error, {
        required String fallback,
      }) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }

    return fallback;
  }

  bool _validateScores() {
    for (final item in _criteria) {
      final raw = _scoreControllers[item.id]?.text.trim() ?? '';

      if (raw.isEmpty) {
        continue;
      }

      final value = double.tryParse(raw.replaceAll(',', '.'));

      if (value == null) {
        _showSnack('Nilai ${item.label} harus berupa angka');
        return false;
      }

      if (value < 0 || value > 100) {
        _showSnack('Nilai ${item.label} harus antara 0 sampai 100');
        return false;
      }
    }

    return true;
  }

  Future<void> _saveEvaluation() async {
    final teacher = _selectedTeacher;

    if (teacher == null) {
      _showSnack('Pilih guru terlebih dahulu');
      return;
    }

    if (!_validateScores()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();

      final skor = _finalScore;
      final predikat = _predicateOf(skor);

      await dio.post(
        ApiEndpoints.teacherEvaluation,
        data: {
          'guru_id': teacher.id,
          'nama_guru': teacher.nama,
          'mapel': teacher.mapel,
          'semester': 'Genap',
          'penilaian': _penilaian,
          'skor': skor,
          'predikat': predikat,
          'catatan': _catatanController.text.trim(),
        },
      );

      _showSnack('Evaluasi kinerja berhasil disimpan');

      _resetForm();
      await _loadHistories();
    } catch (e) {
      _showSnack(
        _messageFromError(
          e,
          fallback: 'Gagal menyimpan evaluasi kinerja',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedTeacherId = null;
      _catatanController.clear();

      for (final controller in _scoreControllers.values) {
        controller.clear();
      }
    });
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

  Future<void> _refresh() async {
    await Future.wait([
      _loadTeachers(),
      _loadHistories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedTeacher = _selectedTeacher;
    final finalScore = _finalScore;
    final predicate = _predicateOf(finalScore);

    return Container(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F7FA),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 12),
            if (_error != null) ...[
              _buildErrorCard(isDark),
              const SizedBox(height: 12),
            ],
            _buildFormCard(
              isDark: isDark,
              selectedTeacher: selectedTeacher,
              finalScore: finalScore,
              predicate: predicate,
            ),
            const SizedBox(height: 16),
            _buildHistoryCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evaluasi Kinerja Guru',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pilih guru-mapel, isi nilai kriteria, lalu simpan evaluasi.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.red.shade900 : Colors.red.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: isDark ? Colors.red.shade200 : Colors.red.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? 'Terjadi kesalahan',
              style: TextStyle(
                color: isDark ? Colors.red.shade100 : Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({
    required bool isDark,
    required _TeacherOption? selectedTeacher,
    required double finalScore,
    required String predicate,
  }) {
    final scoreColor = _colorOf(finalScore);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedTeacherId,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              labelText:
              _loadingGuru ? 'Memuat guru-mapel...' : 'Pilih Guru Mapel',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.person_search_outlined),
            ),
            items: _teachers.map((teacher) {
              final mapelText =
              teacher.mapel.isEmpty || teacher.mapel == '-' ? '' : ' — ${teacher.mapel}';
              final emailText =
              teacher.email.isEmpty || teacher.email == '-' ? '' : ' — ${teacher.email}';

              return DropdownMenuItem<String>(
                value: teacher.id,
                child: Text(
                  '${teacher.nama}$mapelText$emailText',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _loadingGuru
                ? null
                : (value) {
              setState(() {
                _selectedTeacherId = value;
              });
            },
          ),
          if (!_loadingGuru && _teachers.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Belum ada user dengan role guru-mapel yang ditemukan.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
          if (selectedTeacher != null) ...[
            const SizedBox(height: 12),
            _buildSelectedTeacherCard(
              isDark: isDark,
              teacher: selectedTeacher,
            ),
            const SizedBox(height: 16),
            Text(
              'Penilaian Kriteria',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            ..._criteria.map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildCriteriaInput(
                  isDark: isDark,
                  item: item,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _buildFinalScoreBox(
              isDark: isDark,
              score: finalScore,
              predicate: predicate,
              color: scoreColor,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _catatanController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Catatan / Rekomendasi',
                hintText: 'Catatan evaluasi dan rekomendasi pengembangan...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _resetForm,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveEvaluation,
                    icon: _saving
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedTeacherCard({
    required bool isDark,
    required _TeacherOption teacher,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.blue.shade900 : Colors.blue.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teacher.nama,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mapel: ${teacher.mapel}',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          Text(
            'Email: ${teacher.email}',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaInput({
    required bool isDark,
    required _EvaluationCriteria item,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Bobot: ${item.weight}%',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: TextField(
              controller: _scoreControllers[item.id],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '0-100',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalScoreBox({
    required bool isDark,
    required double score,
    required String predicate,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Nilai Akhir',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '($predicate)',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Riwayat Evaluasi',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadingHistory ? null : _loadHistories,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          if (_loadingHistory)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_histories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada data evaluasi kinerja guru.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._histories.map(
                  (item) => _buildHistoryItem(
                isDark: isDark,
                item: item,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required bool isDark,
    required _EvaluationHistory item,
  }) {
    final score = item.skor;
    final color = _colorOf(score);
    final predicate =
    item.predikat.isNotEmpty ? item.predikat : _predicateOf(score);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(
                  Icons.person,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaGuru,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mapel: ${item.mapel}',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      predicate,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _criteria.map((criteria) {
              final raw = item.penilaian[criteria.id];
              final value = _EvaluationHistory._toDouble(raw);

              return _MiniScore(
                label: criteria.label,
                value: value,
                color: _colorOf(value),
              );
            }).toList(),
          ),
          if (item.catatan.isNotEmpty && item.catatan != '-') ...[
            const SizedBox(height: 10),
            Text(
              item.catatan,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Evaluator: ${item.evaluatorNama} • ${item.evaluatorRole} • ${_formatDate(item.createdAt)}',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniScore({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final shortLabel = label.length > 18 ? '${label.substring(0, 18)}...' : label;

    return Container(
      width: 106,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Column(
        children: [
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            shortLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}