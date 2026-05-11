import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.grey900,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.grey600),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.grey400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey400,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.grey200,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: AppColors.black,
        onSurface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.white,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light ? AppColors.grey900 : AppColors.white;

    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w700, color: color),
      displayMedium: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w700, color: color),
      displaySmall: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w600, color: color),
      headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w600, color: color),
      headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: color),
      headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      titleSmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, color: color),
      bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: color),
      labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      labelSmall: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: color),
    );
  }
}
