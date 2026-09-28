import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget Kartu Metriks Sensor Modular (DHT22, MQ-2, MQ-7)
class SensorMetricCard extends StatelessWidget {
  final String title;
  final String pinLabel;
  final String value;
  final String unit;
  final String badgeText;
  final bool isDanger;
  final Color accentColor;
  final IconData icon;
  final double progressPercent;

  const SensorMetricCard({
    super.key,
    required this.title,
    required this.pinLabel,
    required this.value,
    required this.unit,
    required this.badgeText,
    required this.isDanger,
    required this.accentColor,
    required this.icon,
    this.progressPercent = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final badgeBg = isDanger
        ? AppColors.dangerRed.withOpacity(0.18)
        : AppColors.safeEmerald.withOpacity(0.12);
    final badgeColor = isDanger ? AppColors.dangerRed : AppColors.safeEmerald;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDanger
              ? AppColors.dangerRed.withOpacity(0.6)
              : accentColor.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDanger ? AppColors.dangerRed : accentColor).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pinLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercent.clamp(0.0, 1.0),
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDanger ? AppColors.dangerRed : accentColor,
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor.withOpacity(0.3)),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: badgeColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
