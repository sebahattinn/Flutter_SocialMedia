class Conversation {
  final String id;
  final DateTime createdAt;

  Conversation({required this.id, required this.createdAt});

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    id: j['id'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}
