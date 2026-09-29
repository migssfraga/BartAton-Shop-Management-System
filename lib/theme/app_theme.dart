import 'package:flutter/material.dart';

/// BartAton Shop System — Brand Colors
/// Keep this file as the SINGLE source of truth for colors.
/// Every screen/widget should import AppColors instead of hardcoding hex values.
class AppColors {
  static const Color background = Color(0xFF050619); // Dark Navy / Almost Black
  static const Color surface = Color(0xFF090B24); // Deep Navy (cards, sidebar)
  static const Color surfaceLight = Color(0xFF10133A); // slightly lighter card for contrast
  static const Color gold = Color(0xFFFFD400); // Primary accent
  static const Color darkGold = Color(0xFFD9AA00); // Pressed / secondary gold
  static const Color lightGray = Color(0xFFD8D8D8); // Secondary text
  static const Color white = Color(0xFFFFFFFF);

  // Status colors (used sparingly, per the brief)
  static const Color success = Color(0xFF2ECC71);
  static const Color danger = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFFF8A3D);

  static const Color border = Color(0xFF1E2148); // subtle borders
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.darkGold,
        surface: AppColors.surface,
        onPrimary: AppColors.background,
        onSurface: AppColors.lightGray,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.white,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.lightGray),
        hintStyle: const TextStyle(color: Color(0xFF7A7E9E)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.background,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 22),
        titleMedium: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: AppColors.lightGray),
        bodySmall: TextStyle(color: Color(0xFF9296B8)),
      ),
      dividerColor: AppColors.border,
    );
  }
}
