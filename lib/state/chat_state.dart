import 'package:flutter/foundation.dart';
import '../models/message.dart';

@immutable
class ChatState {
  final bool connected;
  final String? conversationId;
  final List<ChatMessage> messages;

  const ChatState({
    required this.connected,
    required this.messages,
    required this.conversationId,
  });

  const ChatState.initial()
    : connected = false,
      messages = const [],
      conversationId = null;

  ChatState copyWith({
    bool? connected,
    String? conversationId,
    List<ChatMessage>? messages,
  }) {
    return ChatState(
      connected: connected ?? this.connected,
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
    );
  }
}
