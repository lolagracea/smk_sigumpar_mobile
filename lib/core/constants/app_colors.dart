import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand ─────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0); // Deep Blue
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);
  static const Color secondary = Color(0xFFE65100); // Deep Orange (aksen)
  static const Color secondaryLight = Color(0xFFFF833A);
  static const Color secondaryDark = Color(0xFFAC1900);

  // ─── Neutral ───────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0A0A0A);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ─── Semantic ──────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0277BD);
  static const Color infoLight = Color(0xFFE1F5FE);

  // ─── Surface (Light) ───────────────────────────────────
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F8);

  // ─── Surface (Dark) ────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F1117);
  static const Color surfaceDark = Color(0xFF1A1D27);
  static const Color surfaceVariantDark = Color(0xFF252836);

  // ─── Feature Colors ────────────────────────────────────
  static const Color academic = Color(0xFF1565C0);
  static const Color studentService = Color(0xFF2E7D32);
  static const Color learning = Color(0xFF6A1B9A);
  static const Color vocational = Color(0xFFE65100);
  static const Color assetService = Color(0xFF00695C);

  // ─── Text & Border Helpers ─────────────────────────────
  static const Color textPrimary = black;
  static const Color textSecondary = grey600;
  static const Color textTertiary = grey500;
  static const Color border = grey300;
}
