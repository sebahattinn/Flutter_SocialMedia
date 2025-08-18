class ChatMessage {
  final String id;
  final String text;
  final DateTime at;
  final bool mine;
  ChatMessage(this.id, this.text, this.at, this.mine);
}

class ChatModel {
  final List<ChatMessage> messages;
  final bool connected;
  const ChatModel({this.messages = const [], this.connected = false});

  ChatModel copyWith({List<ChatMessage>? messages, bool? connected}) =>
      ChatModel(
        messages: messages ?? this.messages,
        connected: connected ?? this.connected,
      );
}
