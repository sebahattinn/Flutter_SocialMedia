import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../state/chat_controller.dart';
import '../../models/message.dart';
import '../../dev_fake_auth.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String otherUserId;
  const ChatPage({super.key, required this.otherUserId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _ctrl = TextEditingController();
  final _sb = Supabase.instance.client;

  // Notifier'ı saklamak yerine metodlarını closure olarak saklıyoruz
  late final Future<void> Function({required String otherUserId}) _connect;
  late final void Function() _disconnect;
  late final void Function(String) _sendMsg;

  bool _sentSeenForThisBuild = false;

  @override
  void initState() {
    super.initState();

    // initState'te bir kez al: ref'le işin bitti
    final notifier = ref.read(chatControllerProvider.notifier);
    _connect = notifier.connect;
    _disconnect = notifier.disconnect;
    _sendMsg = notifier.send;

    Future.microtask(() async {
      await _connect(otherUserId: widget.otherUserId);
      if (!mounted) return;
      // gerekirse burada setState(...) vb. yap
    });
  }

  @override
  void dispose() {
    // ref'e dokunmadan çağırıyoruz
    try {
      _disconnect();
    } catch (_) {}
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _markSeenIfNeeded(String? chatId, List<ChatMessage> msgs) async {
    if (chatId == null || msgs.isEmpty || _sentSeenForThisBuild) return;
    try {
      if (kDevNoAuth) {
        await _sb.rpc(
          'mark_receipts_seen_dev',
          params: {'p_chat': chatId, 'p_user': kDevMyUid},
        );
      } else {
        await _sb.rpc('mark_receipts_seen', params: {'p_chat': chatId});
      }
      _sentSeenForThisBuild = true;
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _fetchOtherPerson() async {
    try {
      final res = await _sb
          .from('people_search')
          .select('id, handle, name, avatar_url')
          .eq('id', widget.otherUserId)
          .maybeSingle();
      if (res == null) return null;
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      debugPrint('people_search fetch error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(chatControllerProvider);
    final messages = model.messages;

    _markSeenIfNeeded(model.chatId, messages);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchOtherPerson(),
          builder: (context, snap) {
            final name =
                (snap.data?['name'] as String?) ??
                (snap.data?['handle'] as String?) ??
                'Sohbet';
            final avatarUrl = snap.data?['avatar_url'] as String?;
            final initial = name.isNotEmpty
                ? name.characters.first.toUpperCase()
                : '?';

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Text(initial, style: const TextStyle(fontSize: 16))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Henüz mesaj yok'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages.reversed.elementAt(i);
                      return Align(
                        alignment: m.mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: m.mine
                                ? Colors.blueAccent.withOpacity(.25)
                                : Colors.grey.withOpacity(.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(m.text),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    _sentSeenForThisBuild = false;
    _sendMsg(text); // notifier yerine closure
  }
}
