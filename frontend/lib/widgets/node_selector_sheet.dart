import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Modal Bottom Sheet untuk memilih Node Perangkat IoT (Replika Dropdown Web Dashboard)
class NodeSelectorSheet extends StatelessWidget {
  final String currentNodeId;
  final ValueChanged<String> onNodeSelected;

  const NodeSelectorSheet({
    super.key,
    required this.currentNodeId,
    required this.onNodeSelected,
  });

  static const List<Map<String, String>> nodes = [
    {'id': 'NODE-MRS01', 'desc': 'Bengkel Mekatronika (Soldering Zone 1)'},
    {'id': 'NODE-MRS02', 'desc': 'Bengkel Mekatronika (Welding Zone 2)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Node IoT Sensor',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...nodes.map((item) {
            final nodeId = item['id']!;
            final desc = item['desc']!;
            final isSelected = nodeId == currentNodeId;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected ? AppColors.safeEmerald.withValues(alpha: 0.5) : AppColors.cardOutline,
                  ),
                ),
                tileColor: isSelected ? AppColors.safeEmerald.withValues(alpha: 0.12) : AppColors.background,
                leading: Icon(
                  Icons.sensors_rounded,
                  color: isSelected ? AppColors.safeEmerald : AppColors.primaryLight,
                ),
                title: Text(
                  nodeId,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.safeEmerald : Colors.white,
                  ),
                ),
                subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.safeEmerald, size: 20) : null,
                onTap: () {
                  onNodeSelected(nodeId);
                  Navigator.pop(context);
                },
              ),
            );
          }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
