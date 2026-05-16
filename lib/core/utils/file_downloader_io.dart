// import 'dart:convert';
// import 'dart:io';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:open_filex/open_filex.dart';
//
// import '../di/injection_container.dart';
// import '../network/dio_client.dart';
//
// Future<void> downloadFile({
//   required BuildContext context,
//   required String? source,
//   required String fileName,
//   String? baseUrl,
// }) async {
//   if (source == null || source.isEmpty) {
//     _snack(context, 'Lampiran tidak tersedia');
//     return;
//   }
//
//   final isBase64 = _isBase64(source);
//   String finalUrl = '';
//   Uint8List? fileBytes;
//   String detectedFileName = fileName;
//
//   if (isBase64) {
//     try {
//       final base64Str = source.contains(',') ? source.split(',').last : source;
//       fileBytes = base64Decode(base64Str);
//       final ext = _detectExtensionFromBytes(fileBytes);
//       if (!detectedFileName.toLowerCase().endsWith('.$ext')) {
//         detectedFileName = '$detectedFileName.$ext';
//       }
//     } catch (e) {
//       _snack(context, 'File rusak: $e');
//       return;
//     }
//   } else {
//     if (source.startsWith('http')) {
//       finalUrl = source;
//     } else if (baseUrl != null) {
//       final cleanBase = baseUrl.endsWith('/')
//           ? baseUrl.substring(0, baseUrl.length - 1)
//           : baseUrl;
//       final cleanPath = source.startsWith('/') ? source : '/$source';
//       finalUrl = '$cleanBase$cleanPath';
//     } else {
//       finalUrl = source;
//     }
//
//     final urlFileName = finalUrl.split('/').last.split('?').first;
//     if (urlFileName.contains('.') &&
//         !detectedFileName.toLowerCase().contains('.')) {
//       final ext = urlFileName.split('.').last;
//       detectedFileName = '$detectedFileName.$ext';
//     }
//   }
//
//   try {
//     _snack(context, 'Mengunduh file...');
//
//     // ─── Tentukan folder save dengan strategi platform-aware ──
//     final saveDir = await _getSaveDirectory(context);
//     if (saveDir == null) {
//       if (context.mounted) _snack(context, 'Tidak bisa akses folder');
//       return;
//     }
//
//     final savePath = '${saveDir.path}/$detectedFileName';
//     debugPrint('📁 Save path: $savePath');
//
//     if (fileBytes != null) {
//       // Base64 → langsung tulis bytes (tidak perlu network)
//       final file = File(savePath);
//       await file.writeAsBytes(fileBytes);
//     } else {
//       // Pakai Dio dari DioClient (token otomatis ke-attach)
//       final dioClient = sl<DioClient>();
//       await dioClient.dio.download(
//         finalUrl,
//         savePath,
//         options: Options(
//           validateStatus: (status) => status != null && status < 400,
//         ),
//       );
//     }
//
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'File tersimpan: $detectedFileName',
//             style: const TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.green.shade700,
//           duration: const Duration(seconds: 5),
//           action: SnackBarAction(
//             label: 'Buka',
//             textColor: Colors.white,
//             onPressed: () => OpenFilex.open(savePath),
//           ),
//         ),
//       );
//     }
//   } catch (e) {
//     debugPrint('❌ Download error: $e');
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       _snack(context, 'Gagal mengunduh: $e');
//     }
//   }
// }
//
// /// Tentukan folder save berdasarkan platform & Android version.
// Future<Directory?> _getSaveDirectory(BuildContext context) async {
//   if (Platform.isIOS) {
//     return await getApplicationDocumentsDirectory();
//   }
//
//   if (Platform.isAndroid) {
//     final sdkInt = await _getAndroidSdkInt();
//     debugPrint('📱 Android SDK: $sdkInt');
//
//     if (sdkInt >= 30) {
//       // ─── Android 11+ (API 30+) ──────────────────────────
//       // Pakai app-specific external storage. TIDAK butuh permission.
//       // Path: /storage/emulated/0/Android/data/<package>/files/Downloads/
//       final dir = await getExternalStorageDirectory();
//       if (dir != null) {
//         final downloadDir = Directory('${dir.path}/Downloads');
//         if (!await downloadDir.exists()) {
//           await downloadDir.create(recursive: true);
//         }
//         return downloadDir;
//       }
//       return await getApplicationDocumentsDirectory();
//     } else if (sdkInt >= 29) {
//       // ─── Android 10 (API 29) ────────────────────────────
//       // Scoped storage. App-specific juga, tidak butuh permission.
//       final dir = await getExternalStorageDirectory();
//       if (dir != null) {
//         final downloadDir = Directory('${dir.path}/Downloads');
//         if (!await downloadDir.exists()) {
//           await downloadDir.create(recursive: true);
//         }
//         return downloadDir;
//       }
//     } else {
//       // ─── Android 9 ke bawah (API ≤ 28) ──────────────────
//       // Butuh permission. Coba folder Downloads publik.
//       final status = await Permission.storage.request();
//       if (status.isGranted) {
//         final publicDir = Directory('/storage/emulated/0/Download');
//         if (await publicDir.exists()) return publicDir;
//       }
//       // Fallback ke app-specific kalau permission ditolak
//       return await getExternalStorageDirectory();
//     }
//   }
//
//   return await getApplicationDocumentsDirectory();
// }
//
// /// Get Android SDK version (API level).
// /// Pakai device_info_plus untuk akurasi.
// Future<int> _getAndroidSdkInt() async {
//   try {
//     if (Platform.isAndroid) {
//       final info = await DeviceInfoPlugin().androidInfo;
//       return info.version.sdkInt;
//     }
//   } catch (e) {
//     debugPrint('Gagal cek SDK: $e');
//   }
//   return 30; // fallback aman ke Android 11
// }
//
// bool _isBase64(String s) {
//   if (s.startsWith('http')) return false;
//   if (s.startsWith('/storage/') || s.startsWith('/uploads/')) return false;
//   if (s.startsWith('data:')) return true;
//   return s.startsWith('JVBERi') ||
//       s.startsWith('/9j/') ||
//       s.startsWith('iVBORw0KGgo') ||
//       s.startsWith('UEsDB');
// }
//
// String _detectExtensionFromBytes(Uint8List bytes) {
//   if (bytes.length < 4) return 'bin';
//   if (bytes[0] == 0x25 &&
//       bytes[1] == 0x50 &&
//       bytes[2] == 0x44 &&
//       bytes[3] == 0x46) return 'pdf';
//   if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return 'jpg';
//   if (bytes[0] == 0x89 &&
//       bytes[1] == 0x50 &&
//       bytes[2] == 0x4E &&
//       bytes[3] == 0x47) return 'png';
//   if (bytes[0] == 0x50 && bytes[1] == 0x4B) return 'docx';
//   return 'bin';
// }
//
// void _snack(BuildContext context, String msg) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text(msg, style: const TextStyle(color: Colors.white)),
//       backgroundColor: Colors.blueGrey.shade800,
//     ),
//   );
// }

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

import '../di/injection_container.dart';
import '../network/dio_client.dart';

Future<void> downloadFile({
  required BuildContext context,
  required String? source,
  required String fileName,
  String? baseUrl,
}) async {
  debugPrint('');
  debugPrint('╔═══════════════════════════════════════════╗');
  debugPrint('║   📥 DOWNLOAD FILE DIMULAI                ║');
  debugPrint('╚═══════════════════════════════════════════╝');
  debugPrint('📌 source: $source');
  debugPrint('📌 fileName: $fileName');
  debugPrint('📌 baseUrl: $baseUrl');

  if (source == null || source.isEmpty) {
    debugPrint('❌ source kosong, batal');
    _snack(context, 'Lampiran tidak tersedia');
    return;
  }

  final isBase64 = _isBase64(source);
  String finalUrl = '';
  Uint8List? fileBytes;
  String detectedFileName = fileName;

  debugPrint('📌 isBase64: $isBase64');

  if (isBase64) {
    try {
      final base64Str = source.contains(',') ? source.split(',').last : source;
      fileBytes = base64Decode(base64Str);
      final ext = _detectExtensionFromBytes(fileBytes);
      if (!detectedFileName.toLowerCase().endsWith('.$ext')) {
        detectedFileName = '$detectedFileName.$ext';
      }
      debugPrint('✅ Base64 decoded, ext: $ext, size: ${fileBytes.length} bytes');
    } catch (e) {
      debugPrint('❌ Base64 decode error: $e');
      _snack(context, 'File rusak: $e');
      return;
    }
  } else {
    if (source.startsWith('http')) {
      finalUrl = source;
    } else if (baseUrl != null) {
      final cleanBase = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final cleanPath = source.startsWith('/') ? source : '/$source';
      finalUrl = '$cleanBase$cleanPath';
    } else {
      finalUrl = source;
    }

    final urlFileName = finalUrl.split('/').last.split('?').first;
    if (urlFileName.contains('.') &&
        !detectedFileName.toLowerCase().contains('.')) {
      final ext = urlFileName.split('.').last;
      detectedFileName = '$detectedFileName.$ext';
    }
    debugPrint('🌐 finalUrl: $finalUrl');
    debugPrint('📝 detectedFileName: $detectedFileName');
  }

  try {
    _snack(context, 'Mengunduh file...');

    final saveDir = await _getSaveDirectory(context);
    if (saveDir == null) {
      debugPrint('❌ saveDir null, batal');
      if (context.mounted) _snack(context, 'Tidak bisa akses folder');
      return;
    }

    final savePath = '${saveDir.path}/$detectedFileName';
    debugPrint('');
    debugPrint('╔═══════════════════════════════════════════╗');
    debugPrint('║   💾 LOKASI PENYIMPANAN                   ║');
    debugPrint('╚═══════════════════════════════════════════╝');
    debugPrint('📁 Folder: ${saveDir.path}');
    debugPrint('📄 File path: $savePath');
    debugPrint('');

    if (fileBytes != null) {
      debugPrint('💾 Menulis base64 ke disk...');
      final file = File(savePath);
      await file.writeAsBytes(fileBytes);
      debugPrint('✅ File base64 tersimpan');
    } else {
      debugPrint('🌐 Download via Dio...');
      final dioClient = sl<DioClient>();
      await dioClient.dio.download(
        finalUrl,
        savePath,
        options: Options(
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      debugPrint('✅ Download via Dio sukses');
    }

    // Verifikasi file benar-benar ada
    final savedFile = File(savePath);
    final exists = await savedFile.exists();
    final size = exists ? await savedFile.length() : 0;
    debugPrint('🔍 File exists? $exists');
    debugPrint('🔍 File size: $size bytes');
    debugPrint('');

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✓ File tersimpan',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detectedFileName,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Buka',
            textColor: Colors.white,
            onPressed: () async {
              final result = await OpenFilex.open(savePath);
              debugPrint('🔓 OpenFilex result: ${result.message}');
            },
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ Download error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _snack(context, 'Gagal mengunduh: $e');
    }
  }
}

/// Strategi pemilihan folder:
/// 1. Coba folder Downloads publik (butuh permission di Android lama)
/// 2. Kalau permission ditolak ATAU folder tidak bisa diakses,
///    fallback ke app-specific external storage (tidak butuh permission)
Future<Directory?> _getSaveDirectory(BuildContext context) async {
  debugPrint('');
  debugPrint('╔═══════════════════════════════════════════╗');
  debugPrint('║   🗂️  CARI FOLDER PENYIMPANAN              ║');
  debugPrint('╚═══════════════════════════════════════════╝');
  debugPrint('🔍 Platform: ${Platform.operatingSystem}');
  debugPrint('🔍 OS Version: ${Platform.operatingSystemVersion}');

  if (Platform.isIOS) {
    final dir = await getApplicationDocumentsDirectory();
    debugPrint('🍎 iOS Documents: ${dir.path}');
    return dir;
  }

  if (Platform.isAndroid) {
    // ─── Strategi 1: Coba folder Downloads publik ──────
    try {
      debugPrint('🔐 Request Permission.storage...');
      final status = await Permission.storage.request();
      debugPrint('🔐 Status permission: $status');

      if (status.isGranted) {
        debugPrint('✅ Permission GRANTED');
        final publicDir = Directory('/storage/emulated/0/Download');
        final exists = await publicDir.exists();
        debugPrint('📂 Folder /storage/emulated/0/Download ada? $exists');
        if (exists) {
          debugPrint('✅ Pakai folder Downloads publik');
          return publicDir;
        }
      } else {
        debugPrint('⚠️ Permission DENIED/RESTRICTED (normal di Android 11+)');
      }
    } catch (e) {
      debugPrint('💥 Permission request error: $e');
    }

    // ─── Strategi 2: App-specific external storage ──
    debugPrint('⚠️ Fallback ke app-specific external storage');
    try {
      final dir = await getExternalStorageDirectory();
      debugPrint('📁 getExternalStorageDirectory: ${dir?.path}');

      if (dir != null) {
        final downloadDir = Directory('${dir.path}/Downloads');
        if (!await downloadDir.exists()) {
          debugPrint('📁 Membuat folder Downloads...');
          await downloadDir.create(recursive: true);
        }
        debugPrint('✅ Folder siap: ${downloadDir.path}');
        return downloadDir;
      }
    } catch (e) {
      debugPrint('💥 getExternalStorageDirectory error: $e');
    }
  }

  // ─── Strategi 3: Last resort ───────────────────────────
  final fallback = await getApplicationDocumentsDirectory();
  debugPrint('🆘 Last resort - Documents: ${fallback.path}');
  return fallback;
}

bool _isBase64(String s) {
  if (s.startsWith('http')) return false;
  if (s.startsWith('/storage/') || s.startsWith('/uploads/')) return false;
  if (s.startsWith('data:')) return true;
  return s.startsWith('JVBERi') ||
      s.startsWith('/9j/') ||
      s.startsWith('iVBORw0KGgo') ||
      s.startsWith('UEsDB');
}

String _detectExtensionFromBytes(Uint8List bytes) {
  if (bytes.length < 4) return 'bin';
  if (bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46) return 'pdf';
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return 'jpg';
  if (bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) return 'png';
  if (bytes[0] == 0x50 && bytes[1] == 0x4B) return 'docx';
  return 'bin';
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.blueGrey.shade800,
    ),
  );
}