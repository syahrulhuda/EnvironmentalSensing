import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Floating Action Button Asisten AI ESI dengan Ambient Glow dan Online Pulsing Dot
class EsiFabButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EsiFabButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        elevation: 0,
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          side: BorderSide(color: AppColors.cardOutline),
        ),
        icon: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0284C7)]),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(color: AppColors.safeEmerald, shape: BoxShape.circle),
            ),
          ],
        ),
        label: const Text(
          'Tanya ESI AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

