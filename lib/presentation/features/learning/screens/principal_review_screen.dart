import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

class _LearningDeviceDocument {
  final int id;
  final String guruId;
  final String namaGuru;
  final String namaDokumen;
  final String jenisDokumen;
  final String fileName;
  final String fileMime;
  final String statusReview;
  final String catatanReview;
  final String reviewedBy;
  final String reviewedAt;
  final int versi;
  final int? parentId;
  final String tanggalUpload;

  const _LearningDeviceDocument({
    required this.id,
    required this.guruId,
    required this.namaGuru,
    required this.namaDokumen,
    required this.jenisDokumen,
    required this.fileName,
    required this.fileMime,
    required this.statusReview,
    required this.catatanReview,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.versi,
    required this.parentId,
    required this.tanggalUpload,
  });

  factory _LearningDeviceDocument.fromJson(Map<String, dynamic> json) {
    return _LearningDeviceDocument(
      id: _toInt(json['id']),
      guruId: (json['guru_id'] ?? '').toString(),
      namaGuru: (json['nama_guru'] ?? json['namaGuru'] ?? '-').toString(),
      namaDokumen:
      (json['nama_dokumen'] ?? json['namaDokumen'] ?? '-').toString(),
      jenisDokumen:
      (json['jenis_dokumen'] ?? json['jenisDokumen'] ?? 'Lainnya')
          .toString(),
      fileName: (json['file_name'] ?? json['fileName'] ?? '-').toString(),
      fileMime:
      (json['file_mime'] ?? json['fileMime'] ?? 'application/octet-stream')
          .toString(),
      statusReview:
      (json['status_review'] ?? json['statusReview'] ?? 'menunggu')
          .toString(),
      catatanReview:
      (json['catatan_review'] ?? json['catatanReview'] ?? '').toString(),
      reviewedBy: (json['reviewed_by'] ?? json['reviewedBy'] ?? '').toString(),
      reviewedAt: (json['reviewed_at'] ?? json['reviewedAt'] ?? '').toString(),
      versi: _toInt(json['versi'], fallback: 1),
      parentId: json['parent_id'] == null ? null : _toInt(json['parent_id']),
      tanggalUpload:
      (json['tanggal_upload'] ?? json['tanggalUpload'] ?? '-').toString(),
    );
  }

  bool get isImage => fileMime.toLowerCase().startsWith('image/');

  bool get isPdf {
    final lowerMime = fileMime.toLowerCase();
    final lowerName = fileName.toLowerCase();

    return lowerMime == 'application/pdf' || lowerName.endsWith('.pdf');
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}

class _ReviewHistoryItem {
  final int id;
  final int perangkatId;
  final String status;
  final String komentar;
  final String reviewerRole;
  final String reviewerNama;
  final DateTime? createdAt;

  const _ReviewHistoryItem({
    required this.id,
    required this.perangkatId,
    required this.status,
    required this.komentar,
    required this.reviewerRole,
    required this.reviewerNama,
    required this.createdAt,
  });

  factory _ReviewHistoryItem.fromJson(Map<String, dynamic> json) {
    return _ReviewHistoryItem(
      id: _toInt(json['id']),
      perangkatId: _toInt(json['perangkat_id']),
      status: (json['status'] ?? '-').toString(),
      komentar: (json['komentar'] ?? '').toString(),
      reviewerRole: (json['reviewer_role'] ?? '-').toString(),
      reviewerNama: (json['reviewer_nama'] ?? '-').toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}

class PrincipalReviewScreen extends StatefulWidget {
  const PrincipalReviewScreen({super.key});

  @override
  State<PrincipalReviewScreen> createState() => _PrincipalReviewScreenState();
}

class _PrincipalReviewScreenState extends State<PrincipalReviewScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  bool _downloading = false;
  String? _error;

  List<_LearningDeviceDocument> _documents = [];

  String _search = '';
  String _selectedStatus = '';
  String _selectedJenis = '';

  static const List<String> _statusOptions = [
    '',
    'menunggu',
    'disetujui',
    'revisi',
    'ditolak',
  ];

  static const List<String> _jenisOptions = [
    '',
    'RPP',
    'Silabus',
    'Modul',
    'Prota',
    'Promes',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();

      final response = await dio.get(
        ApiEndpoints.learningDevices,
        queryParameters: {
          if (_search.trim().isNotEmpty) 'search': _search.trim(),
          if (_selectedStatus.isNotEmpty) 'status_review': _selectedStatus,
          if (_selectedJenis.isNotEmpty) 'jenis_dokumen': _selectedJenis,
        },
      );

      final rows = _extractList(response.data);

      setState(() {
        _documents = rows
            .whereType<Map>()
            .map(
              (item) => _LearningDeviceDocument.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .where((item) => item.id > 0)
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = _messageFromError(
          e,
          fallback: 'Gagal memuat data perangkat pembelajaran',
        );
        _documents = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<Uint8List> _fetchDocumentBytes(_LearningDeviceDocument doc) async {
    final dio = sl<DioClient>();

    final response = await dio.get(
      ApiEndpoints.learningDeviceDownload(doc.id),
      options: Options(responseType: ResponseType.bytes),
    );

    final raw = response.data;

    if (raw is Uint8List) {
      return raw;
    }

    if (raw is List<int>) {
      return Uint8List.fromList(raw);
    }

    throw Exception('Format file tidak valid');
  }

  Future<void> _downloadDocument(_LearningDeviceDocument doc) async {
    setState(() {
      _downloading = true;
    });

    try {
      final bytes = await _fetchDocumentBytes(doc);
      final extension = _extensionFromFileName(doc.fileName);

      await FileSaver.instance.saveFile(
        name: _safeFileNameWithoutExtension(doc.fileName),
        bytes: bytes,
        ext: extension,
        mimeType: MimeType.other,
      );

      _showSnack('Dokumen berhasil diunduh');
    } catch (e) {
      _showSnack(
        _messageFromError(
          e,
          fallback: 'Gagal mengunduh dokumen',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  Future<void> _previewDocument(_LearningDeviceDocument doc) async {
    setState(() {
      _downloading = true;
    });

    try {
      final bytes = await _fetchDocumentBytes(doc);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return _PreviewDialog(
            doc: doc,
            bytes: bytes,
            onDownload: () => _downloadDocument(doc),
          );
        },
      );
    } catch (e) {
      _showSnack(
        _messageFromError(
          e,
          fallback: 'Gagal memuat dokumen',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  Future<void> _submitReview({
    required _LearningDeviceDocument doc,
    required String status,
    required String catatan,
  }) async {
    try {
      final dio = sl<DioClient>();

      await dio.put(
        ApiEndpoints.learningDeviceReviewKepsek(doc.id),
        data: {
          'status': status,
          'catatan': catatan.trim().isEmpty ? null : catatan.trim(),
        },
      );

      _showSnack('Review berhasil disimpan');
      await _loadDocuments();
    } catch (e) {
      _showSnack(
        _messageFromError(
          e,
          fallback: 'Gagal menyimpan review',
        ),
      );
    }
  }

  Future<void> _openReviewDialog(_LearningDeviceDocument doc) async {
    await showDialog(
      context: context,
      builder: (context) {
        return _ReviewDialog(
          doc: doc,
          onSubmit: (status, catatan) async {
            await _submitReview(
              doc: doc,
              status: status,
              catatan: catatan,
            );
          },
        );
      },
    );
  }

  Future<void> _openHistoryDialog(_LearningDeviceDocument doc) async {
    try {
      final dio = sl<DioClient>();

      final responses = await Future.wait([
        dio.get(ApiEndpoints.learningDeviceReviewHistory(doc.id)),
        dio.get(ApiEndpoints.learningDeviceVersions(doc.id)),
      ]);

      final historyRows = _extractList(responses[0].data);
      final versionRows = _extractList(responses[1].data);

      final histories = historyRows
          .whereType<Map>()
          .map(
            (item) => _ReviewHistoryItem.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();

      final versions = versionRows
          .whereType<Map>()
          .map(
            (item) => _LearningDeviceDocument.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .where((item) => item.id > 0)
          .toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return _HistoryDialog(
            doc: doc,
            histories: histories,
            versions: versions,
            onPreview: _previewDocument,
            onDownload: _downloadDocument,
          );
        },
      );
    } catch (e) {
      _showSnack(
        _messageFromError(
          e,
          fallback: 'Gagal memuat riwayat dokumen',
        ),
      );
    }
  }

  void _resetFilter() {
    setState(() {
      _search = '';
      _selectedStatus = '';
      _selectedJenis = '';
      _searchController.clear();
    });

    _loadDocuments();
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

  String _safeFileNameWithoutExtension(String fileName) {
    final name = fileName.trim().isEmpty ? 'dokumen-perangkat' : fileName;
    final dotIndex = name.lastIndexOf('.');

    final baseName = dotIndex > 0 ? name.substring(0, dotIndex) : name;

    final sanitized = baseName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]+'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');

    return sanitized.isEmpty ? 'dokumen-perangkat' : sanitized;
  }

  String _extensionFromFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return 'bin';
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'menunggu':
        return 'Menunggu';
      case 'disetujui':
        return 'Disetujui';
      case 'revisi':
        return 'Revisi';
      case 'ditolak':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'menunggu':
        return const Color(0xFFD97706);
      case 'disetujui':
        return const Color(0xFF16A34A);
      case 'revisi':
        return const Color(0xFF2563EB);
      case 'ditolak':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  Color _jenisColor(String jenis) {
    switch (jenis) {
      case 'RPP':
        return const Color(0xFF2563EB);
      case 'Silabus':
        return const Color(0xFF16A34A);
      case 'Modul':
        return const Color(0xFF9333EA);
      case 'Prota':
        return const Color(0xFFD97706);
      case 'Promes':
        return const Color(0xFFEA580C);
      default:
        return Colors.grey;
    }
  }

  int get _countMenunggu {
    return _documents.where((item) => item.statusReview == 'menunggu').length;
  }

  int get _countDisetujui {
    return _documents.where((item) => item.statusReview == 'disetujui').length;
  }

  int get _countRevisi {
    return _documents.where((item) => item.statusReview == 'revisi').length;
  }

  int get _countDitolak {
    return _documents.where((item) => item.statusReview == 'ditolak').length;
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

    return Container(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F7FA),
      child: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 12),
                _buildFilterCard(isDark),
                const SizedBox(height: 12),
                _buildSummaryGrid(isDark),
                const SizedBox(height: 12),
                if (_error != null)
                  _buildError()
                else if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 56),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_documents.isEmpty)
                    _buildEmpty()
                  else
                    ..._documents.map(
                          (doc) => _buildDocumentCard(
                        doc: doc,
                        isDark: isDark,
                      ),
                    ),
              ],
            ),
            if (_downloading)
              Container(
                color: Colors.black.withOpacity(0.12),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
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
            'Pemeriksaan Perangkat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Cari dokumen berdasarkan nama dokumen, nama guru, status, dan jenis dokumen.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
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
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Cari Dokumen / Guru',
              hintText: 'Contoh: RPP Matematika / Budi',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _search = value;
              });
            },
            onSubmitted: (_) => _loadDocuments(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.isEmpty
                            ? 'Semua Status'
                            : _statusLabel(status),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? '';
                    });
                    _loadDocuments();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedJenis,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Jenis',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _jenisOptions.map((jenis) {
                    return DropdownMenuItem(
                      value: jenis,
                      child: Text(jenis.isEmpty ? 'Semua Jenis' : jenis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedJenis = value ?? '';
                    });
                    _loadDocuments();
                  },
                ),
              ),
            ],
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
                  onPressed: _loadDocuments,
                  icon: const Icon(Icons.search),
                  label: const Text('Cari'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryBox(
          label: 'Total',
          value: _documents.length,
          color: Colors.grey,
        ),
        _SummaryBox(
          label: 'Menunggu',
          value: _countMenunggu,
          color: const Color(0xFFD97706),
        ),
        _SummaryBox(
          label: 'Disetujui',
          value: _countDisetujui,
          color: const Color(0xFF16A34A),
        ),
        _SummaryBox(
          label: 'Revisi',
          value: _countRevisi,
          color: const Color(0xFF2563EB),
        ),
        _SummaryBox(
          label: 'Ditolak',
          value: _countDitolak,
          color: const Color(0xFFDC2626),
        ),
      ],
    );
  }

  Widget _buildDocumentCard({
    required _LearningDeviceDocument doc,
    required bool isDark,
  }) {
    final statusColor = _statusColor(doc.statusReview);
    final jenisColor = _jenisColor(doc.jenisDokumen);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: jenisColor.withOpacity(0.12),
                child: Icon(
                  Icons.description_outlined,
                  color: jenisColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  doc.namaDokumen,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              _StatusBadge(
                label: _statusLabel(doc.statusReview),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Guru: ${doc.namaGuru}',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'File: ${doc.fileName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MiniTag(
                text: doc.jenisDokumen,
                color: jenisColor,
              ),
              _MiniTag(
                text: 'Versi ${doc.versi}',
                color: const Color(0xFF2563EB),
              ),
              _MiniTag(
                text: doc.tanggalUpload,
                color: Colors.grey,
              ),
            ],
          ),
          if (doc.catatanReview.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Catatan: ${doc.catatanReview}',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _previewDocument(doc),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Lihat'),
              ),
              ElevatedButton.icon(
                onPressed: () => _openReviewDialog(doc),
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Review'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openHistoryDialog(doc),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Riwayat'),
              ),
              OutlinedButton.icon(
                onPressed: () => _downloadDocument(doc),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Unduh'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 10),
          Text(
            _error ?? 'Terjadi kesalahan',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadDocuments,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Belum ada dokumen perangkat yang cocok dengan filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _PreviewDialog extends StatelessWidget {
  final _LearningDeviceDocument doc;
  final Uint8List bytes;
  final VoidCallback onDownload;

  const _PreviewDialog({
    required this.doc,
    required this.bytes,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = doc.isImage;
    final isPdf = doc.isPdf;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 720,
          maxWidth: 900,
        ),
        child: Column(
          children: [
            Container(
              color: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      doc.namaDokumen,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Unduh',
                    onPressed: onDownload,
                    icon: const Icon(Icons.download, color: Colors.white),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isImage
                  ? InteractiveViewer(
                child: Center(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              )
                  : isPdf
                  ? SfPdfViewer.memory(
                bytes,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                enableDoubleTapZooming: true,
                enableTextSelection: true,
              )
                  : _NonImagePreview(
                fileName: doc.fileName,
                fileMime: doc.fileMime,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NonImagePreview extends StatelessWidget {
  final String fileName;
  final String fileMime;

  const _NonImagePreview({
    required this.fileName,
    required this.fileMime,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              fileMime,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 14),
            const Text(
              'Format ini tidak dapat ditampilkan langsung di preview. Gunakan tombol unduh untuk membuka file.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final _LearningDeviceDocument doc;
  final Future<void> Function(String status, String catatan) onSubmit;

  const _ReviewDialog({
    required this.doc,
    required this.onSubmit,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final TextEditingController _catatanController = TextEditingController();

  String _status = 'disetujui';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _catatanController.text = widget.doc.catatanReview;
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final catatan = _catatanController.text.trim();

    if ((_status == 'revisi' || _status == 'ditolak') && catatan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan wajib diisi untuk revisi atau penolakan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    await widget.onSubmit(_status, catatan);

    if (mounted) {
      setState(() {
        _submitting = false;
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Review Dokumen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.doc.namaDokumen,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Guru: ${widget.doc.namaGuru}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Keputusan',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'disetujui',
                  child: Text('Setujui'),
                ),
                DropdownMenuItem(
                  value: 'revisi',
                  child: Text('Minta Revisi'),
                ),
                DropdownMenuItem(
                  value: 'ditolak',
                  child: Text('Tolak'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _status = value ?? 'disetujui';
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _catatanController,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                labelText:
                _status == 'disetujui' ? 'Catatan Opsional' : 'Catatan',
                hintText: _status == 'disetujui'
                    ? 'Tambahkan catatan jika diperlukan...'
                    : 'Jelaskan bagian yang perlu diperbaiki atau alasan penolakan...',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _submitting ? null : _handleSubmit,
          icon: _submitting
              ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.save),
          label: Text(_submitting ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
    );
  }
}

class _HistoryDialog extends StatelessWidget {
  final _LearningDeviceDocument doc;
  final List<_ReviewHistoryItem> histories;
  final List<_LearningDeviceDocument> versions;
  final void Function(_LearningDeviceDocument doc) onPreview;
  final void Function(_LearningDeviceDocument doc) onDownload;

  const _HistoryDialog({
    required this.doc,
    required this.histories,
    required this.versions,
    required this.onPreview,
    required this.onDownload,
  });

  String _formatDate(DateTime? value) {
    if (value == null) return '-';

    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(value.toLocal());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'disetujui':
        return const Color(0xFF16A34A);
      case 'revisi':
        return const Color(0xFF2563EB);
      case 'ditolak':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'menunggu':
        return 'Menunggu';
      case 'disetujui':
        return 'Disetujui';
      case 'revisi':
        return 'Revisi';
      case 'ditolak':
        return 'Ditolak';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: DefaultTabController(
        length: 2,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            children: [
              Container(
                color: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Riwayat: ${doc.namaDokumen}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
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
              const TabBar(
                tabs: [
                  Tab(text: 'Review'),
                  Tab(text: 'Versi'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    histories.isEmpty
                        ? const Center(
                      child: Text(
                        'Belum ada riwayat review.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: histories.length,
                      itemBuilder: (context, index) {
                        final item = histories[index];
                        final color = _statusColor(item.status);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              left: BorderSide(color: color, width: 4),
                            ),
                            color: color.withOpacity(0.06),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statusLabel(item.status),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reviewer: ${item.reviewerNama} (${item.reviewerRole})',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(item.createdAt),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              if (item.komentar.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(item.komentar),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    versions.isEmpty
                        ? const Center(
                      child: Text(
                        'Belum ada riwayat versi dokumen.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: versions.length,
                      itemBuilder: (context, index) {
                        final item = versions[index];

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${item.versi}'),
                            ),
                            title: Text(item.namaDokumen),
                            subtitle: Text(
                              '${item.fileName}\n${item.tanggalUpload}',
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  tooltip: 'Lihat',
                                  onPressed: () => onPreview(item),
                                  icon: const Icon(Icons.visibility),
                                ),
                                IconButton(
                                  tooltip: 'Unduh',
                                  onPressed: () => onDownload(item),
                                  icon: const Icon(Icons.download),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniTag({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}