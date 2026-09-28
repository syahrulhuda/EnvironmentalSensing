import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget Banner Status Keselamatan Darurat K3 ESS
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
    final bgColor = isDanger
        ? AppColors.dangerRed.withOpacity(0.18)
        : AppColors.safeEmerald.withOpacity(0.10);
    final borderColor = isDanger ? AppColors.dangerRed : AppColors.safeEmerald;
    final icon = isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded;
    final title = isDanger ? 'PERINGATAN: KONDISI BENGKEL KRITIS!' : 'Bengkel Terpantau Aman';
    final desc = isDanger
        ? 'Sensor mendeteksi anomali: Suhu, Gas CO, atau Asap melebihi batas K3. LED Merah & Kipas Aktif!'
        : 'Parameter atmosfer ruangan dalam ambang baku mutu K3 & OSHA. Tidak ada kebocoran gas.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: borderColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: borderColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: borderColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
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
