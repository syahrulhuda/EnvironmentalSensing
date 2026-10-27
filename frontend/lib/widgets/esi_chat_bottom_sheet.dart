import 'package:flutter/material.dart';
import '../services/esi_chat_service.dart';
import 'esi_chat_panel.dart';

/// Modal Bottom Sheet Obrolan ESI AI untuk Mobile (Opsi B)
class EsiChatBottomSheet extends StatelessWidget {
  final EsiChatService chatService;

  const EsiChatBottomSheet({super.key, required this.chatService});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
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
    );
  }
}
