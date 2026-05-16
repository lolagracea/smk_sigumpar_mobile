import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'core/di/injection_container.dart' as di;
import 'app.dart';

void main() async {
  // 1. Pastikan binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize locale Indonesia untuk DateFormat
  await initializeDateFormatting('id_ID', null);

  // 3. Set orientasi layar (Hanya Portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 4. Initialize MediaStore (hanya untuk Android, untuk download file ke folder publik)
  if (!kIsWeb && Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = 'SMK Sigumpar';
  }

  // 5. Setup dependency injection (Service Locator)
  // Di sinilah AuthProvider dkk dibuat
  await di.init();

  // 6. Jalankan aplikasi
  runApp(const SmkSigumparApp());
}