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
import 'package:saver_gallery/saver_gallery.dart';

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

  if (source == null || source.isEmpty) {
    _snack(context, 'Lampiran tidak tersedia');
    return;
  }

  final isBase64 = _isBase64(source);
  String finalUrl = '';
  Uint8List? fileBytes;
  String detectedFileName = fileName;
  String detectedExt = 'bin';

  if (isBase64) {
    try {
      final base64Str = source.contains(',') ? source.split(',').last : source;
      fileBytes = base64Decode(base64Str);
      detectedExt = _detectExtensionFromBytes(fileBytes);
      if (!detectedFileName.toLowerCase().endsWith('.$detectedExt')) {
        detectedFileName = '$detectedFileName.$detectedExt';
      }
    } catch (e) {
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
    if (urlFileName.contains('.')) {
      detectedExt = urlFileName.split('.').last.toLowerCase();
      if (!detectedFileName.toLowerCase().contains('.')) {
        detectedFileName = '$detectedFileName.$detectedExt';
      }
    }
    debugPrint('🌐 finalUrl: $finalUrl');
  }

  debugPrint('📝 detectedFileName: $detectedFileName');
  debugPrint('📝 detectedExt: $detectedExt');

  // Cek apakah file ini adalah gambar
  final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(detectedExt);
  debugPrint('🖼️ isImage: $isImage');

  try {
    _snack(context, 'Mengunduh file...');

    // ─── Untuk GAMBAR: save ke Galeri (Pictures folder) ──
    if (isImage && Platform.isAndroid) {
      // Get bytes
      Uint8List? imageBytes = fileBytes;
      if (imageBytes == null) {
        debugPrint('🌐 Fetch image bytes via Dio...');
        final dioClient = sl<DioClient>();
        final response = await dioClient.dio.get(
          finalUrl,
          options: Options(
            responseType: ResponseType.bytes,
            validateStatus: (status) => status != null && status < 400,
          ),
        );
        imageBytes = Uint8List.fromList(response.data as List<int>);
      }

      debugPrint('💾 Save ke Gallery (Pictures/SMK Sigumpar)...');
      final result = await SaverGallery.saveImage(
        imageBytes,
        fileName: detectedFileName,
        androidRelativePath: 'Pictures/SMK Sigumpar',
        skipIfExists: false,
      );

      debugPrint('✅ Gallery save result: ${result.isSuccess}');
      debugPrint('📁 File path: ${result.filePath}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✓ Tersimpan di Galeri',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pictures/SMK Sigumpar/$detectedFileName',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 6),
            ),
          );
        } else {
          _snack(context, 'Gagal simpan ke galeri');
        }
      }
      return;
    }

    // ─── Untuk PDF/DOC: save ke app-specific folder + bisa share ──
    final saveDir = await _getSaveDirectory();
    if (saveDir == null) {
      if (context.mounted) _snack(context, 'Tidak bisa akses folder');
      return;
    }

    final savePath = '${saveDir.path}/$detectedFileName';
    debugPrint('📄 Save path: $savePath');

    if (fileBytes != null) {
      final file = File(savePath);
      await file.writeAsBytes(fileBytes);
    } else {
      final dioClient = sl<DioClient>();
      await dioClient.dio.download(
        finalUrl,
        savePath,
        options: Options(
          validateStatus: (status) => status != null && status < 400,
        ),
      );
    }

    final savedFile = File(savePath);
    final exists = await savedFile.exists();
    final size = exists ? await savedFile.length() : 0;
    debugPrint('🔍 File exists? $exists, size: $size bytes');

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✓ File tersimpan',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
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

/// App-specific external storage (tidak butuh permission)
Future<Directory?> _getSaveDirectory() async {
  if (Platform.isIOS) {
    return await getApplicationDocumentsDirectory();
  }

  if (Platform.isAndroid) {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir != null) {
        final downloadDir = Directory('${dir.path}/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      }
    } catch (e) {
      debugPrint('💥 getExternalStorageDirectory error: $e');
    }
  }

  return await getApplicationDocumentsDirectory();
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