import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'mini_sparkline_painter.dart';

/// Widget Kartu Metriks Sensor Desain Industri Modern (Identik 100% dengan Web Dashboard)
/// Menampilkan nilai telemetri 2-baris, status badge K3, dan drawer grafik sparkline mini real-time
class SensorMetricCard extends StatelessWidget {
  final String title, pinLabel, value, unit, badgeText, thresholdInfo, sparklineTitle;
  final bool isDanger, isWarning;
  final IconData icon;
  final List<double> sparklineValues;

  const SensorMetricCard({
    super.key,
    required this.title,
    required this.pinLabel,
    required this.value,
    required this.unit,
    required this.badgeText,
    this.thresholdInfo = '',
    required this.isDanger,
    this.isWarning = false,
    required this.icon,
    this.sparklineValues = const [],
    this.sparklineTitle = 'TREN REAL-TIME',
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isDanger ? AppColors.dangerRed : (isWarning ? AppColors.warningAmber : AppColors.safeEmerald);
    final cardBorder = isDanger ? AppColors.dangerRed.withValues(alpha: 0.70) : (isWarning ? AppColors.warningAmber.withValues(alpha: 0.60) : AppColors.cardOutline);
    final hasSecondaryMetric = unit.contains('% RH');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6)),
          if (isDanger) BoxShadow(color: AppColors.dangerRed.withValues(alpha: 0.18), blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Baris 1: Icon Box + Judul & Pill Badge K3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.28)),
                    ),
                    child: Icon(icon, color: AppColors.primaryLight, size: 17),
                  ),
                  const SizedBox(width: 9),
                  Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 5, height: 5, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(badgeText, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Baris 2: Nilai Metriks Utama Bergaya Bold Typographic
          hasSecondaryMetric
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•', style: TextStyle(fontSize: 18, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                    ),
                    Text(unit, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3)),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                    const SizedBox(width: 6),
                    Text(unit, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryLight, letterSpacing: 0.5)),
                  ],
                ),
          const SizedBox(height: 12),

          // 3. Mini Sparkline Graph Drawer (Persis Web card-graph-drawer)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sparklineTitle, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textMuted, fontFamily: 'monospace')),
                  Text(thresholdInfo, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: Color(0x9038BDF8))),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 52,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x1838BDF8)),
                ),
                child: CustomPaint(
                  painter: MiniSparklinePainter(
                    values: sparklineValues.isNotEmpty ? sparklineValues : [0.0, 0.0],
                    lineColor: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Baris 4: Pin Hardware Micro-Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x2038BDF8)),
            ),
            child: Text(
              pinLabel,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textMuted, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
