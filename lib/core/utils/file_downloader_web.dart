import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> downloadFile({
  required BuildContext context,
  required String? source,
  required String fileName,
  String? baseUrl,
}) async {
  if (source == null || source.isEmpty) {
    _snack(context, 'Lampiran tidak tersedia');
    return;
  }

  String finalUrl;

  // Kalau base64, ubah jadi data URL
  if (_isBase64(source)) {
    final base64Str = source.contains(',') ? source.split(',').last : source;
    final mime = _detectMime(base64Str);
    finalUrl = 'data:$mime;base64,$base64Str';
  } else if (source.startsWith('http')) {
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

  try {
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (context.mounted) {
        _snack(context, 'File dibuka di tab baru');
      }
    } else {
      if (context.mounted) _snack(context, 'Tidak bisa membuka file');
    }
  } catch (e) {
    if (context.mounted) _snack(context, 'Gagal: $e');
  }
}

bool _isBase64(String s) {
  if (s.startsWith('http')) return false;
  if (s.startsWith('/storage/') || s.startsWith('/uploads/')) return false;
  if (s.startsWith('data:')) return false;
  return s.startsWith('JVBERi') ||
      s.startsWith('/9j/') ||
      s.startsWith('iVBORw0KGgo') ||
      s.startsWith('UEsDB');
}

String _detectMime(String base64Str) {
  if (base64Str.startsWith('JVBERi')) return 'application/pdf';
  if (base64Str.startsWith('/9j/')) return 'image/jpeg';
  if (base64Str.startsWith('iVBORw0KGgo')) return 'image/png';
  if (base64Str.startsWith('UEsDB')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  return 'application/octet-stream';
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.blueGrey.shade800,
    ),
  );
}