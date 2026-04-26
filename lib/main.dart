import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/di/injection_container.dart' as di;
import 'presentation/common/providers/auth_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Setup dependency injection
  await di.init();

  // Tunggu pengecekan token selesai sebelum menggambar UI aplikasi
  // Ini mencegah layar berkedip ke halaman Login saat user sebenarnya sudah login
  final authProvider = di.sl<AuthProvider>();
  await authProvider.checkAuthStatus();

  runApp(const SmkSigumparApp());
}