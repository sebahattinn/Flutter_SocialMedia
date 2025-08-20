import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../dev_fake_auth.dart'; // kDevNoAuth, kDevMyUid

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) => ChatController(ref, ChatService()),
);

class ChatState {
  final bool connected;
  final List<ChatMessage> messages;
  final String? chatId;

  const ChatState({
    this.connected = false,
    this.messages = const [],
    this.chatId,
  });

  ChatState copyWith({
    bool? connected,
    List<ChatMessage>? messages,
    String? chatId,
  }) {
    return ChatState(
      connected: connected ?? this.connected,
      messages: messages ?? this.messages,
      chatId: chatId ?? this.chatId,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this.ref, this._svc) : super(const ChatState());

  final Ref ref;
  final ChatService _svc;

  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSub;

  SupabaseClient get _sb => Supabase.instance.client;

  Future<void> connect({required String otherUserId}) async {
    // DEV veya gerçek auth?
    final myId = kDevNoAuth
        ? kDevMyUid
        : (_sb.auth.currentUser?.id ??
              (throw StateError('Auth bekleniyordu ama yok.')));

    debugPrint('connect -> myId=$myId otherUserId=$otherUserId');

    // (Web token’ı) dev modda gerek yok; gerçek auth varsa Realtime'a aktar
    if (!kDevNoAuth) {
      final token = _sb.auth.currentSession?.accessToken;
      if (token != null) _sb.realtime.setAuth(token);
    }

    // chatId bul/oluştur (authsuz da çalışır)
    final chatId = await _svc.ensureChat(myId, otherUserId);
    debugPrint('connect -> chatId=$chatId');
    state = state.copyWith(chatId: chatId);

    // geçmiş mesajlar
    final initial = await _svc.fetchMessages(chatId, myId);
    state = state.copyWith(messages: initial);

    // realtime subscribe
    await _channel?.unsubscribe();
    _channel = _svc.subscribeToMessages(
      chatId: chatId,
      myUid: myId,
      onInsert: (msg) {
        debugPrint('realtime insert -> ${msg.text}');
        state = state.copyWith(messages: [...state.messages, msg]);

        // Karşıdan gelen (mine=false) mesaj düştüyse, okundu olarak işaretle
        if (!msg.mine) {
          _markReceiptsSeen(chatId: chatId, myUid: myId);
        }
      },
      onSubscribed: () {
        debugPrint('realtime subscribed!');
        state = state.copyWith(connected: true);

        // Ekrana girildi ve subscribe edildi -> mevcut okunmamışları "görüldü" yap
        _markReceiptsSeen(chatId: chatId, myUid: myId);
      },
    );

    // Auth event dinleme (dev modda kapalı)
    if (!kDevNoAuth) {
      _authSub?.cancel();
      _authSub = _sb.auth.onAuthStateChange.listen((data) {
        final t = data.session?.accessToken;
        if (t != null) _sb.realtime.setAuth(t);
      });
    }
  }

  Future<void> disconnect() async {
    await _channel?.unsubscribe();
    await _authSub?.cancel();
    _channel = null;
    state = state.copyWith(connected: false);
  }

  Future<void> send(String text) async {
    if (state.chatId == null || text.trim().isEmpty) return;
    final myId = kDevNoAuth ? kDevMyUid : _sb.auth.currentUser!.id;
    await _svc.sendMessage(chatId: state.chatId!, text: text, senderId: myId);
    // Gönderenden gelen mesaj için okundu işaretlemeye gerek aslında var
  }

  // --- helpers ---

  /// Bu sohbet için current user'ın okunmamışlarını "seen" yapar.
  Future<void> _markReceiptsSeen({
    required String chatId,
    required String myUid,
  }) async {
    try {
      if (kDevNoAuth) {
        await _sb.rpc(
          'mark_receipts_seen_dev',
          params: {'p_chat': chatId, 'p_user': myUid},
        );
      } else {
        // Auth varken fonksiyon auth.uid() kullanır
        await _sb.rpc('mark_receipts_seen', params: {'p_chat': chatId});
      }
      debugPrint('mark seen ok -> chat=$chatId user=$myUid');
    } catch (e) {
      debugPrint('mark seen error: $e');
    }
  }
}
