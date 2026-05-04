// ─────────────────────────────────────────────────────────────────────────────
// lib/presentation/features/vocational/screens/pdf_preview_screen.dart
//
// PdfPreviewScreen — tampilkan PDF secara inline dari bytes
//
// FEATURE PARITY WEB → MOBILE:
//   Web  : PreviewModal → <embed src="blob:..."> atau <iframe>
//   Mobile: SfPdfViewer.memory(bytes) — render langsung tanpa download dulu
//
// Fitur:
//   ✅ Render PDF inline dari Uint8List (tanpa simpan dulu)
//   ✅ AppBar: judul + nama file + tombol Unduh
//   ✅ Bottom bar: navigasi halaman (prev / page X dari Y / next)
//   ✅ Loading indicator saat PDF dimuat
//   ✅ Error state dengan tombol Unduh sebagai fallback
//   ✅ Return value 'download' → caller trigger download
//
// Package: syncfusion_flutter_pdfviewer: ^26.2.14
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreviewScreen extends StatefulWidget {
  /// Raw PDF bytes dari API response
  final Uint8List bytes;

  /// Judul laporan (ditampilkan di AppBar)
  final String title;

  /// Nama file asli dari backend (mis: laporan-pramuka.pdf)
  final String fileName;

  const PdfPreviewScreen({
    super.key,
    required this.bytes,
    required this.title,
    required this.fileName,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final PdfViewerController _pdfController = PdfViewerController();

  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _hasError = false;

  static const _primaryBlue = Color(0xFF1565C0);

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade800,

      // ── AppBar — mirror web PreviewModal header ────────────────
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.fileName.isNotEmpty)
              Text(
                widget.fileName,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          // Tombol Unduh — mirror web PreviewModal download button
          // Return 'download' → ScoutReportScreen._handleLihatFile trigger download
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'download'),
            icon: const Icon(
              Icons.download_rounded,
              color: Colors.greenAccent,
              size: 18,
            ),
            label: const Text(
              'Unduh',
              style: TextStyle(color: Colors.greenAccent, fontSize: 12),
            ),
          ),
        ],
      ),

      // ── Body: PDF Viewer inline ────────────────────────────────
      body: Stack(
        children: [
          // SfPdfViewer.memory = render PDF dari bytes tanpa file sementara
          SfPdfViewer.memory(
            widget.bytes,
            controller: _pdfController,
            enableTextSelection: false,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _totalPages = details.document.pages.count;
                _isLoading = false;
              });
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            },
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() => _currentPage = details.newPageNumber);
            },
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memuat PDF...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error state — fallback ke download
          if (_hasError)
            Container(
              color: Colors.grey.shade900,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 72,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Gagal menampilkan PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'File mungkin rusak atau format tidak didukung.\nCoba unduh dan buka dengan aplikasi PDF.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, 'download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text(
                          'Unduh File',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // ── Bottom bar: navigasi halaman ──────────────────────────
      bottomNavigationBar: (!_isLoading && !_hasError && _totalPages > 0)
          ? Container(
              height: 44,
              color: _primaryBlue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tombol halaman sebelumnya
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () => _pdfController.previousPage()
                        : null,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: _currentPage > 1
                          ? Colors.white
                          : Colors.white38,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                  ),

                  // Label halaman
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Halaman $_currentPage dari $_totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Tombol halaman berikutnya
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () => _pdfController.nextPage()
                        : null,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _currentPage < _totalPages
                          ? Colors.white
                          : Colors.white38,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}