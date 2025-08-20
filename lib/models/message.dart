class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool mine; // UI için

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.mine,
  });

  /// Supabase satırını modele çevirir
  factory ChatMessage.fromRow(Map<String, dynamic> row, String myUid) {
    final ca = row['created_at'];
    final dt = ca is String ? DateTime.parse(ca) : (ca as DateTime);
    return ChatMessage(
      id: (row['id'] ?? '').toString(),
      chatId: row['chat_id'] as String,
      senderId: row['sender_id'] as String,
      text: (row['text'] ?? '') as String,
      createdAt: dt,
      mine: (row['sender_id'] as String) == myUid,
    );
  }

  /// Insert için map
  Map<String, dynamic> toInsertMap() => {
    'chat_id': chatId,
    'sender_id': senderId,
    'text': text,
    // created_at DB default now()
  };
}
