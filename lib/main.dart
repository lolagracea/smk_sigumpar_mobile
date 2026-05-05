import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← Import baru
import 'core/di/injection_container.dart' as di;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale Indonesia untuk DateFormat
  // Wajib supaya format tanggal "Senin, 15 Januari 2025" bekerja
  await initializeDateFormatting('id_ID', null);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Setup dependency injection
  await di.init();

  runApp(const SmkSigumparApp());
}