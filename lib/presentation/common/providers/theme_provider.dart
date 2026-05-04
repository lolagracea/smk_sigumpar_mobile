import 'package:flutter/material.dart';
import '../../../core/theme/theme_notifier.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeNotifier _notifier;

  ThemeProvider({required ThemeNotifier notifier}) : _notifier = notifier {
    _notifier.addListener(notifyListeners);
  }

  ThemeMode get themeMode => _notifier.themeMode;
  bool get isDark => _notifier.isDark;

  Future<void> toggleTheme() => _notifier.toggleTheme();
  Future<void> setTheme(ThemeMode mode) => _notifier.setTheme(mode);

  @override
  void dispose() {
    _notifier.removeListener(notifyListeners);
    super.dispose();
  }
}
