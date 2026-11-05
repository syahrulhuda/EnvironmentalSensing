import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget Pill Badge Status Real-Time (Identik dengan Header Glass Web)
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
    final bgAlpha = isLive ? 0.15 : 0.20;
    final borderAlpha = isLive ? 0.40 : 0.50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: borderAlpha)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
