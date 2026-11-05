import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'status_pill_badge.dart';

/// Widget Header Modern Dashboard ESS (Pinned SliverAppBar)
/// 100% Identik dengan Web Dashboard (K3 Squircle Indicator, Dynamic Title, Node Pill & Status Pill)
class DashboardHeader extends StatelessWidget {
  final String nodeId;
  final bool isOnline;
  final bool isDanger;
  final VoidCallback onSelectNode;

  const DashboardHeader({
    super.key,
    required this.nodeId,
    required this.isOnline,
    required this.isDanger,
    required this.onSelectNode,
  });

  @override
  Widget build(BuildContext context) {
    final k3Color = isDanger
        ? AppColors.dangerRed
        : (isOnline ? AppColors.safeEmerald : AppColors.dangerRed);

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.card.withValues(alpha: 0.92),
      toolbarHeight: 68,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: k3Color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: k3Color.withValues(alpha: 0.40)),
            ),
            child: Icon(Icons.sensors_rounded, color: k3Color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Environmental Sensing System',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  'Bengkel Mekatronika ($nodeId)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Dropdown Pill Node Selector (Identik persis Web Dashboard NODE-MRS01 v)
        InkWell(
          onTap: onSelectNode,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardOutline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nodeId,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Live K3 Heartbeat Status Pill (ONLINE hijau berkedip / OFFLINE merah)
        StatusPillBadge(isLive: isOnline, label: isOnline ? 'ONLINE' : 'OFFLINE'),
        const SizedBox(width: 10),
      ],
    );
  }
}
