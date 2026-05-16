import 'package:flutter/material.dart';

// Conditional import: pilih implementasi sesuai platform
import 'file_downloader_io.dart'
if (dart.library.html) 'file_downloader_web.dart' as impl;

class FileDownloader {
  /// Download file dari URL atau base64 string.
  /// - Mobile (Android/iOS) → save ke Downloads folder + tombol Buka
  /// - Web → buka di tab baru (browser handle preview/download)
  static Future<void> downloadFile({
    required BuildContext context,
    required String? source,
    required String fileName,
    String? baseUrl,
  }) async {
    return impl.downloadFile(
      context: context,
      source: source,
      fileName: fileName,
      baseUrl: baseUrl,
    );
  }
}