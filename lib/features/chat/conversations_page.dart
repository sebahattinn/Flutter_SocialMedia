import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dev_fake_auth.dart';
import '../../services/chat_service.dart';
import '../../models/profile_brief.dart';
import 'chat_page.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  final _svc = ChatService();
  late final String myUid;

  Future<(List<_ChatListItem>, List<ProfileBrief>)> _load() async {
    myUid = kDevNoAuth
        ? kDevMyUid
        : (Supabase.instance.client.auth.currentUser!.id);

    // 1) Benim chatlerim
    final chats = await _svc.listChats(myUid);
    // 2) Her chat için karşı taraf id
    final others = <String>[];
    for (final c in chats) {
      final List<dynamic> arr = c['user_ids'];
      final other = arr.firstWhere((u) => u != myUid) as String;
      others.add(other);
    }
    // 3) Profilleri topla
    final profMap = await _svc.fetchProfiles(others);
    final chatItems = <_ChatListItem>[
      for (final c in chats)
        _ChatListItem(
          chatId: c['id'] as String,
          other:
              profMap[(List.from(
                c['user_ids'],
              ).firstWhere((u) => u != myUid))] ??
              ProfileBrief(id: 'unknown', username: 'unknown'),
        ),
    ];

    // 4) Karşılıklı takipler listesi (yeni sohbet başlatmak için)
    final mutuals = await _svc.mutualFollows(myUid);

    return (chatItems, mutuals);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            appBar: _AppBar(title: 'Mesajlar'),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final (items, mutuals) = snap.data!;

        return Scaffold(
          appBar: const _AppBar(title: 'Mesajlar'),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (items.isNotEmpty) ...[
                const _SectionHeader('Sohbetler'),
                for (final it in items)
                  _ChatTile(
                    title: it.other.username,
                    avatarUrl: it.other.avatarUrl,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(otherUserId: it.other.id),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 12),
              ],
              const _SectionHeader('Mesaj atabileceğin kişiler'),
              if (mutuals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Henüz karşılıklı takip yok.'),
                )
              else
                for (final p in mutuals)
                  _ChatTile(
                    title: p.username,
                    avatarUrl: p.avatarUrl,
                    onTap: () async {
                      // Chat yoksa oluşturulacak; ChatPage içinde connect zaten yapıyor
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(otherUserId: p.id),
                        ),
                      );
                    },
                  ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _ChatListItem {
  final String chatId;
  final ProfileBrief other;
  _ChatListItem({required this.chatId, required this.other});
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _AppBar({required this.title, super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final VoidCallback onTap;
  const _ChatTile({required this.title, required this.onTap, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
            ? NetworkImage(avatarUrl!)
            : null,
        child: (avatarUrl == null || avatarUrl!.isEmpty)
            ? Text(title.isNotEmpty ? title[0].toUpperCase() : '?')
            : null,
      ),
      title: Text(title),
      onTap: onTap,
    );
  }
}
