// ─────────────────────────────────────────────────────────────────────────────
// lib/core/utils/download_helper.dart
//
// DownloadHelper — simpan file bytes ke storage device + buka dengan app
//
// Flow mirror web "Download":
//   Web  : klik Download → browser simpan otomatis ke Downloads
//   Mobile: bytes dari API → simpan ke /Downloads → OpenFile.open()
//
// Platform:
//   Android : getExternalStorageDirectories(type: downloads) → /sdcard/Downloads/
//   iOS     : getApplicationDocumentsDirectory() → akses via Files app
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Hasil operasi download
class DownloadResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;

  const DownloadResult._({
    required this.success,
    this.filePath,
    this.errorMessage,
  });

  factory DownloadResult.success(String path) =>
      DownloadResult._(success: true, filePath: path);

  factory DownloadResult.failure(String message) =>
      DownloadResult._(success: false, errorMessage: message);
}

class DownloadHelper {
  DownloadHelper._();

  /// Simpan [bytes] ke storage dengan nama [fileName], lalu buka file.
  ///
  /// Mengembalikan [DownloadResult] berisi status dan path file tersimpan.
  static Future<DownloadResult> saveAndOpen({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      // 1. Minta izin storage (Android ≤ 12)
      if (Platform.isAndroid) {
        await _requestStoragePermission();
      }

      // 2. Tentukan folder tujuan
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        return DownloadResult.failure(
          'Tidak dapat menemukan folder penyimpanan.',
        );
      }

      // 3. Pastikan folder ada
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      // 4. Tulis file dengan nama dari backend
      final safeFileName = _sanitizeFileName(fileName);
      final filePath = '${directory.path}/$safeFileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      // 5. Buka file dengan aplikasi default di device
      final openResult = await OpenFile.open(filePath);
      if (openResult.type == ResultType.noAppToOpen) {
        // File sudah tersimpan meski tidak ada app yang bisa buka
        return DownloadResult.success(filePath);
      }

      return DownloadResult.success(filePath);
    } on FileSystemException catch (e) {
      return DownloadResult.failure('Gagal menyimpan file: ${e.message}');
    } catch (e) {
      return DownloadResult.failure('Error tidak terduga: $e');
    }
  }

  // ── Minta izin storage Android ────────────────────────────────
  static Future<void> _requestStoragePermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  // ── Ambil direktori download sesuai platform ──────────────────
  static Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Android: coba External Downloads terlebih dahulu
      try {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) {
          return dirs.first;
        }
      } catch (_) {}

      // Fallback: internal app Documents
      try {
        return await getApplicationDocumentsDirectory();
      } catch (_) {}
    } else if (Platform.isIOS) {
      // iOS: Documents — dapat diakses via Files app
      try {
        return await getApplicationDocumentsDirectory();
      } catch (_) {}
    }
    return null;
  }

  // ── Sanitize nama file — hapus karakter tidak valid ───────────
  static String _sanitizeFileName(String fileName) {
    final sanitized = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .trim();
    if (sanitized.isEmpty) return 'file_download.bin';
    if (!sanitized.contains('.')) return '$sanitized.bin';
    return sanitized;
  }
}