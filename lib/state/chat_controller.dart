import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import 'chat_state.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final chatControllerProvider = StateNotifierProvider<ChatController, ChatModel>(
  (ref) => ChatController(ref),
);

class ChatController extends StateNotifier<ChatModel> {
  final Ref ref;
  StreamSubscription? _sub;

  ChatController(this.ref) : super(const ChatModel());

  Future<void> connect({String? url}) async {
    final svc = ref.read(chatServiceProvider);
    await svc.connect(url: url);
    state = state.copyWith(connected: true);

    _sub = svc.stream.listen(
      (event) {
        final msg = ChatMessage(
          DateTime.now().microsecondsSinceEpoch.toString(),
          event,
          DateTime.now(),
          false,
        );
        state = state.copyWith(messages: [...state.messages, msg]);
      },
      onDone: () {
        state = state.copyWith(connected: false);
      },
      onError: (_) {
        state = state.copyWith(connected: false);
      },
    );
  }

  void send(String text) {
    if (text.trim().isEmpty) return;
    ref.read(chatServiceProvider).send(text);
    final mine = ChatMessage(
      DateTime.now().microsecondsSinceEpoch.toString(),
      text,
      DateTime.now(),
      true,
    );
    state = state.copyWith(messages: [...state.messages, mine]);
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await ref.read(chatServiceProvider).disconnect();
    state = state.copyWith(connected: false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
