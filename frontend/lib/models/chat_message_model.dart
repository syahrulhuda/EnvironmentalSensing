/// Model Pesan Obrolan ESI AI Assistant
class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  factory ChatMessageModel.user(String text) {
    return ChatMessageModel(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessageModel.esi(String text) {
    return ChatMessageModel(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}
