import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'status_pill_badge.dart';

/// Widget Header Modern Dashboard ESS (Pinned SliverAppBar)
class DashboardHeader extends StatelessWidget {
  final String nodeId;
  final bool isOnline;
  final bool isDanger;
  final bool isDangerSimulated;
  final VoidCallback onToggleSimulation;
  final VoidCallback onOpenSettings;

  const DashboardHeader({
    super.key,
    required this.nodeId,
    required this.isOnline,
    required this.isDanger,
    required this.isDangerSimulated,
    required this.onToggleSimulation,
    required this.onOpenSettings,
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
        StatusPillBadge(isLive: isOnline, label: isOnline ? 'ONLINE' : 'OFFLINE'),
        IconButton(
          icon: Icon(
            Icons.bolt,
            size: 20,
            color: isDangerSimulated ? AppColors.dangerRed : AppColors.textMuted,
          ),
          tooltip: 'Simulasi Bahaya K3',
          onPressed: onToggleSimulation,
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 19, color: AppColors.textSecondary),
          onPressed: onOpenSettings,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
