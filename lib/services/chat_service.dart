import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/profile_brief.dart';

class ChatService {
  final SupabaseClient _sb = Supabase.instance.client;

  /// İki kullanıcı için tekil chat’i garanti eder ve chatId döndürür.
  /// Not: chats(user_ids uuid[]) varsayımı. Şeman farklıysa bu kısmı uyarlayın.
  Future<String> ensureChat(String userA, String userB) async {
    final existing = await _sb.from('chats').select().contains('user_ids', [
      userA,
      userB,
    ]).maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final inserted = await _sb
        .from('chats')
        .insert({
          'user_ids': [userA, userB],
        })
        .select()
        .single();

    return inserted['id'] as String;
  }

  /// Geçmiş mesajları getir
  Future<List<ChatMessage>> fetchMessages(String chatId, String myUid) async {
    final rows = await _sb
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);

    return rows
        .map<ChatMessage>(
          (e) => ChatMessage.fromRow(Map<String, dynamic>.from(e), myUid),
        )
        .toList();
  }

  /// Realtime insert dinle – çağıran unsubscribe edebilir
  RealtimeChannel subscribeToMessages({
    required String chatId,
    required void Function(ChatMessage) onInsert,
    required String myUid,
    void Function()? onSubscribed, // subscribed olunca tetiklenir
  }) {
    final ch = _sb.channel('public:messages:chat_$chatId');

    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_id',
        value: chatId,
      ),
      callback: (payload) {
        onInsert(ChatMessage.fromRow(payload.newRecord, myUid));
      },
    );

    ch.subscribe((status, _) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        onSubscribed?.call();
      }
    });

    return ch;
  }

  /// Mesaj gönder
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String senderId,
  }) async {
    await _sb.from('messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'text': text.trim(),
    });
  }

  /// (Web için önemli) Realtime’a token’ı aktar
  void ensureRealtimeAuth() {
    final token = _sb.auth.currentSession?.accessToken;
    if (token != null) {
      _sb.realtime.setAuth(token);
    }
  }
}

/// ------------------- Extension: Ekstra sorgular -------------------
extension ChatServiceQueries on ChatService {
  /// Bu kullanıcının dahil olduğu tüm chatler
  Future<List<Map<String, dynamic>>> listChats(String myUid) async {
    final rows = await _sb
        .from('chats')
        .select()
        .contains('user_ids', [myUid])
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Bir grup kullanıcı id’si için profilleri getir (id, username, avatar)
  Future<Map<String, ProfileBrief>> fetchProfiles(Iterable<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _sb
        .from('profiles')
        .select('id, username, avatar_url')
        .filter('id', 'in', ids.toList());

    final list = List<Map<String, dynamic>>.from(rows);
    return {for (final r in list) r['id'] as String: ProfileBrief.fromRow(r)};
  }

  /// Karşılıklı takipler (basit intersect ile)
  Future<List<ProfileBrief>> mutualFollows(String myUid) async {
    // 1) Benim takip ettiklerim
    final iFollowRows = await _sb
        .from('follows')
        .select('following_id')
        .eq('follower_id', myUid);
    final iFollow = {
      for (final r in iFollowRows) (r['following_id'] as String),
    };

    // 2) Beni takip edenler
    final followMeRows = await _sb
        .from('follows')
        .select('follower_id')
        .eq('following_id', myUid);
    final followMe = {
      for (final r in followMeRows) (r['follower_id'] as String),
    };

    final mutualIds = iFollow.intersection(followMe);
    final map = await fetchProfiles(mutualIds);
    return map.values.toList();
  }
}
