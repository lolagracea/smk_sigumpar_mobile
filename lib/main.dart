import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  // 4. Setup dependency injection (Service Locator)
  // Di sinilah AuthProvider dkk dibuat
  await di.init();

  // 5. Jalankan aplikasi
  runApp(const SmkSigumparApp());
}