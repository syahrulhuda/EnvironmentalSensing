import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget Badge Status Koneksi RTDB / Simulator
class StatusPillBadge extends StatelessWidget {
  final bool isLive;
  final String label;

  const StatusPillBadge({
    super.key,
    required this.isLive,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLive ? AppColors.safeEmerald : AppColors.dangerRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
