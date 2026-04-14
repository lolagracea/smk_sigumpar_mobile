import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileHelper {
  FileHelper._();

  static const List<String> allowedDocExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx'];
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  static const int maxFileSizeMb = 10;

  /// Buka file picker dan kembalikan PlatformFile
  static Future<PlatformFile?> pickFile({
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
    );

    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  /// Buka image picker
  static Future<PlatformFile?> pickImage() async {
    return pickFile(allowedExtensions: allowedImageExtensions);
  }

  /// Buka document picker
  static Future<PlatformFile?> pickDocument() async {
    return pickFile(allowedExtensions: allowedDocExtensions);
  }

  /// Validasi ukuran file (default max 10MB)
  static bool isFileSizeValid(PlatformFile file, {int maxMb = maxFileSizeMb}) {
    if (file.size == 0) return false;
    final sizeMb = file.size / (1024 * 1024);
    return sizeMb <= maxMb;
  }

  /// Validasi ekstensi file
  static bool isExtensionAllowed(String fileName, List<String> allowed) {
    final ext = getExtension(fileName).toLowerCase();
    return allowed.contains(ext);
  }

  /// Ambil ekstensi file dari nama file
  static String getExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  /// Ambil nama file saja (tanpa path)
  static String getFileName(String path) {
    return File(path).uri.pathSegments.last;
  }

  /// Format ukuran file menjadi string yang mudah dibaca
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
