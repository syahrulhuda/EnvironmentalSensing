import 'package:flutter/material.dart';

/// Palet Desain Industri Modern Navy & Sky Cyan (Identik dengan Web CSS)
/// Mengikuti spesifikasi arsitektur 3-warna di frontend/style.css:
/// 1. Background: #070D1E (Deep Midnight Navy)
/// 2. Card Surface: #0E172E (Rich Slate Blue Glass)
/// 3. Card Outline: #38BDF8 (Crisp Sky Blue 22% Opacity)
/// 4. Typography: #F8FAFC (Crisp White) Across All Cards
/// 5. K3 Indicators: Hijau (#10B981) / Kuning (#F59E0B) / Merah (#EF4444)
class AppColors {
  // 1. Primary Canvas & Surface (Deep Midnight Navy Theme)
  static const Color background = Color(0xFF070D1E);
  static const Color surface = Color(0xFF0B142B);
  static const Color card = Color(0xFF0E172E);
  static const Color cardOutline = Color(0x3838BDF8);
  static const Color border = Color(0x2838BDF8);

  // 2. Brand Cyan / Sky Accent
  static const Color primary = Color(0xFF0284C7);
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color skyGlow = Color(0x4038BDF8);

  // 3. Clean Modern Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // 4. K3 Safety Indicators
  static const Color safeEmerald = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);

  // Compatibility Aliases
  static const Color accent = safeEmerald;
  static const Color tertiary = textSecondary;
  static const Color tempCyan = primaryLight;
  static const Color smokeAmber = warningAmber;
  static const Color coPurple = Color(0xFF818CF8);
}
