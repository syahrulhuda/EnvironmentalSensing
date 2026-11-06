import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/constants/app_colors.dart';
import '../models/chat_message_model.dart';

/// Bubble Pesan Obrolan ESI AI dengan Dukungan Markdown Renderer Lengkap (TD-F14)
class EsiMessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const EsiMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: screenWidth * 0.82),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary.withValues(alpha: 0.28) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser
                ? AppColors.primaryLight.withValues(alpha: 0.45)
                : AppColors.border,
          ),
        ),
        child: isUser
            ? Text(
                message.text,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.38,
                ),
              )
            : MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.42),
                  strong: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  em: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  code: const TextStyle(
                    fontSize: 11.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                    backgroundColor: Color(0x30070D1E),
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardOutline),
                  ),
                  listBullet: const TextStyle(fontSize: 12.5, color: AppColors.primaryLight),
                  h1: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
                  h2: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                  h3: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.white),
                  blockquote: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
                  blockquoteDecoration: BoxDecoration(
                    border: const Border(left: BorderSide(color: AppColors.primaryLight, width: 3)),
                    color: AppColors.background.withValues(alpha: 0.5),
                  ),
                ),
              ),
      ),
    );
  }
}

