import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/chat_message_model.dart';
import '../services/esi_chat_service.dart';

/// Panel Chat ESI AI Reusable & Auto-scrollable (TD-F09)
/// Digunakan sebagai Pinned Panel pada Desktop/Web (Opsi A) dan Bottom Sheet pada Mobile (Opsi B)
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
      'Halo! Saya ESI, asisten AI keselamatan bengkel mekatronika POLTEKOM. '
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header ESI Assistant
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.smart_toy_rounded, color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESI Safety Assistant',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Gemini AI • K3 Guidance',
                        style: TextStyle(fontSize: 10, color: AppColors.tertiary),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.showHeaderClose && widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          // Chat Feed (Scrollable & Auto-scroll)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * (widget.showHeaderClose ? 0.75 : 0.85),
                    ),
                    decoration: BoxDecoration(
                      color: m.isUser ? AppColors.primary.withOpacity(0.2) : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: m.isUser ? AppColors.primary.withOpacity(0.4) : AppColors.border),
                    ),
                    child: Text(
                      m.text,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.35),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: LinearProgressIndicator(
                backgroundColor: AppColors.card,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 3,
              ),
            ),
          // Quick Question Chips
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
          // Input Form
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tanyakan keselamatan bengkel...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.card,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
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
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
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
        backgroundColor: AppColors.card,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        label: Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.tertiary)),
        onPressed: () => _sendMessage(label),
      ),
    );
  }
}
