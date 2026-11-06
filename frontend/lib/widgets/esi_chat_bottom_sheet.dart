import 'package:flutter/material.dart';
import '../services/esi_chat_service.dart';
import 'esi_chat_panel.dart';

/// Modal Bottom Sheet Obrolan ESI AI untuk Mobile dengan Keyboard Inset Aware
class EsiChatBottomSheet extends StatelessWidget {
  final EsiChatService chatService;

  const EsiChatBottomSheet({super.key, required this.chatService});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final statusBarHeight = mediaQuery.padding.top;

    // Hitung tinggi aman agar tidak overflow saat keyboard muncul
    final double maxAvailableHeight = screenHeight - keyboardHeight - statusBarHeight - 16;
    final double desiredHeight = screenHeight * 0.85;
    final double sheetHeight = (desiredHeight > maxAvailableHeight) ? maxAvailableHeight : desiredHeight;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        height: sheetHeight,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: EsiChatPanel(
            chatService: chatService,
            showHeaderClose: true,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}
