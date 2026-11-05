import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget Banner Status Keselamatan K3 Modern Glass (Identik dengan Web Dashboard)
class EmergencyBannerWidget extends StatelessWidget {
  final bool isDanger;
  final String statusText;

  const EmergencyBannerWidget({
    super.key,
    required this.isDanger,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final isOffline = statusText == 'OFFLINE';
    final isWarmup = statusText == 'WARMUP';

    Color themeColor;
    IconData icon;
    String title;
    String description;
    String badge;

    if (isOffline) {
      themeColor = AppColors.dangerRed;
      icon = Icons.wifi_off_rounded;
      title = 'KONEKSI NODE IOT TERPUTUS';
      description = 'Node tidak mengirim telemetri >15 detik. Periksa daya & Wi-Fi perangkat.';
      badge = 'OFFLINE';
    } else if (isDanger) {
      themeColor = AppColors.dangerRed;
      icon = Icons.warning_amber_rounded;
      title = 'STATUS K3: BAHAYA KRITIS!';
      description = 'Kadar gas/asap melebihi ambang batas. Kipas darurat & LED merah aktif.';
      badge = 'DANGER';
    } else if (isWarmup) {
      themeColor = AppColors.primaryLight;
      icon = Icons.hourglass_top_rounded;
      title = 'Pemanasan Sensor (Warmup)';
      description = 'Stabilisasi koil pemanas SnO2 MQ-7/MQ-2 selama 45 detik untuk mencegah alarm palsu.';
      badge = 'WARMUP';
    } else {
      themeColor = AppColors.safeEmerald;
      icon = Icons.verified_user_rounded;
      title = 'Laboratorium Terpantau Aman';
      description = 'Parameter gas, asap, dan suhu ruangan berada di bawah baku mutu K3 & OSHA.';
      badge = 'NORMAL';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.40), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeColor.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: themeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: themeColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: themeColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
