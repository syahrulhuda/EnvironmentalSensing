import 'package:flutter/material.dart';

/// Palet 4-Warna Harmonis & Standar Keselamatan K3 ESS (Pilar 1)
/// Terdiri dari 4 Token Desain Utama + Status Peringatan K3 Bersyarat
class AppColors {
  // 1. Primary: Brand Identity, Active Headers, Buttons & Primary Lines
  static const Color primary = Color(0xFF0284C7); // Slate Cyan
  static const Color primaryLight = Color(0xFF38BDF8); // Glow Cyan

  // 2. Secondary: Dark Slate Surface & Elevated Containers
  static const Color background = Color(0xFF080C14);
  static const Color surface = Color(0xFF0F172A); // Container Surface
  static const Color card = Color(0xFF1E293B); // Elevated Card Surface
  static const Color border = Color(0x1FFFFFFF);

  // 3. Tertiary: Cool Muted Typography & Gridlines
  static const Color tertiary = Color(0xFF94A3B8); // Muted Slate
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // 4. Accent: Interactive Spotlight, AI Dialogue & Live Indicator
  static const Color accent = Color(0xFF10B981); // Neon Mint / Live Green
  static const Color safeEmerald = Color(0xFF10B981);

  // Conditional K3 Safety Alerts (Hanya aktif saat kondisi darurat/peringatan K3)
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  // Legacy Aliases untuk Kompatibilitas Kode yang Ada
  static const Color tempCyan = primaryLight;
  static const Color smokeAmber = warningAmber;
  static const Color coPurple = primary;
}
