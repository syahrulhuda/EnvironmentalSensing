import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Konfigurasi Tema Dark Modern Navy (Sesuai Web Dashboard poltekom-ess.web.app)
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryLight,
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardOutline, width: 1.2),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.safeEmerald,
        surface: AppColors.surface,
        error: AppColors.dangerRed,
      ),
    );
  }
}
