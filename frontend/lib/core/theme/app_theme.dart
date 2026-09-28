import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Konfigurasi Tema Dark Modern untuk Multiplatform (Web & Mobile)
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.tempCyan,
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.tempCyan,
        secondary: AppColors.coPurple,
        surface: AppColors.surface,
        error: AppColors.dangerRed,
      ),
    );
  }
}
