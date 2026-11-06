import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/chat_message_model.dart';
import '../services/esi_chat_service.dart';
import 'esi_message_bubble.dart';

/// Panel Chat ESI AI Modern Glass & Auto-scrollable dengan Markdown Renderer (TD-F09 / TD-F14)
class EsiChatPanel extends StatefulWidget {
  final EsiChatService chatService;
  final VoidCallback? onClose;
  final bool showHeaderClose;

  const EsiChatPanel({
    super.key,
    required this.chatService,
    this.onClose,
    this.showHeaderClose = false,
  });

  @override
  State<EsiChatPanel> createState() => _EsiChatPanelState();
}

class _EsiChatPanelState extends State<EsiChatPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [
    ChatMessageModel.esi(
      'Halo! Saya **ESI**, asisten AI keselamatan bengkel mekatronika POLTEKOM. '
      'Saya memantau sensor DHT22, MQ-7 (CO), dan MQ-2 secara real-time. Ada yang bisa saya bantu?',
    ),
  ];
  final List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessageModel.user(query));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    final reply = await widget.chatService.sendMessage(query, history: _history);
    if (!mounted) return;

    setState(() {
      _messages.add(ChatMessageModel.esi(reply));
      _history.add({'role': 'user', 'content': query});
      _history.add({'role': 'model', 'content': reply});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardOutline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(Icons.smart_toy_rounded, color: AppColors.primaryLight, size: 19),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESI Safety Assistant',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Gemini AI • Analitik K3 Bengkel',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.showHeaderClose && widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0x2038BDF8), height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) => EsiMessageBubble(message: _messages[i]),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryLight),
                  minHeight: 2.5,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _chip('🌡️ Cek Suhu'),
                _chip('⚠️ Bahaya CO (MQ-7)'),
                _chip('🔥 Gas & Asap'),
                _chip('💡 SOP Evakuasi'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tanyakan keselamatan bengkel...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryLight)),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded, size: 17),
                onPressed: () => _sendMessage(_textController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: Color(0x3038BDF8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
        label: Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
        onPressed: () => _sendMessage(label),
      ),
    );
  }
}
