import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/chat_message_model.dart';
import '../services/esi_chat_service.dart';

/// Modal Obrolan Interaktif dengan ESI AI Assistant (FastAPI ReAct)
class EsiChatBottomSheet extends StatefulWidget {
  final EsiChatService chatService;

  const EsiChatBottomSheet({super.key, required this.chatService});

  @override
  State<EsiChatBottomSheet> createState() => _EsiChatBottomSheetState();
}

class _EsiChatBottomSheetState extends State<EsiChatBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessageModel> _messages = [
    ChatMessageModel.esi(
      'Halo! Saya ESI, asisten AI keselamatan bengkel mekatronika POLTEKOM. '
      'Saya memantau sensor DHT22, MQ-7 (CO), dan MQ-2 secara real-time. Ada yang bisa saya bantu?',
    ),
  ];
  final List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessageModel.user(text));
      _isLoading = true;
    });
    _controller.clear();

    final reply = await widget.chatService.sendMessage(text, history: _history);
    if (!mounted) return;

    setState(() {
      _messages.add(ChatMessageModel.esi(reply));
      _history.add({'role': 'user', 'content': text});
      _history.add({'role': 'model', 'content': reply});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.coPurple, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ESI Safety Assistant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: AppColors.border),
          // Daftar Pesan
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? AppColors.tempCyan.withOpacity(0.2)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: m.isUser
                            ? AppColors.tempCyan.withOpacity(0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      m.text,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
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
                valueColor: AlwaysStoppedAnimation(AppColors.coPurple),
              ),
            ),
          // Chips Pertanyaan Cepat
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Tanyakan keselamatan bengkel...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.tempCyan,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.send, size: 18),
                onPressed: () => _sendMessage(_controller.text),
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
        label: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        onPressed: () => _sendMessage(label),
      ),
    );
  }
}
