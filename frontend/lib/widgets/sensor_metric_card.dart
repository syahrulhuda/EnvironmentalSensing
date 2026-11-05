import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget Kartu Metriks Sensor Desain Industri Modern (Identik dengan Web Dashboard)
class SensorMetricCard extends StatelessWidget {
  final String title;
  final String pinLabel;
  final String value;
  final String unit;
  final String badgeText;
  final String thresholdInfo;
  final bool isDanger;
  final bool isWarning;
  final IconData icon;

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
  });

  @override
  Widget build(BuildContext context) {
    // Tentukan warna semantik K3
    final Color statusColor = isDanger
        ? AppColors.dangerRed
        : (isWarning ? AppColors.warningAmber : AppColors.safeEmerald);

    final Color badgeBg = statusColor.withValues(alpha: 0.16);
    final Color badgeBorder = statusColor.withValues(alpha: 0.45);
    final Color cardBorder = isDanger
        ? AppColors.dangerRed.withValues(alpha: 0.70)
        : (isWarning ? AppColors.warningAmber.withValues(alpha: 0.60) : AppColors.cardOutline);

    final bool hasSecondaryMetric = unit.contains('% RH');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          if (isDanger)
            BoxShadow(
              color: AppColors.dangerRed.withValues(alpha: 0.18),
              blurRadius: 16,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris 1: Icon Box + Judul & Pill Badge K3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(icon, color: AppColors.primaryLight, size: 17),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Baris 2: Nilai Metriks Utama Bergaya Bold Typographic
          hasSecondaryMetric
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '•',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 10),

          // Baris 3: Footer Micro-label (Pin Hardware & Ambang K3)
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x1838BDF8), width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x2038BDF8)),
                  ),
                  child: Text(
                    pinLabel,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Text(
                  thresholdInfo,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0x9038BDF8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
