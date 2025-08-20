import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../chat/chat_page.dart';
import '../../dev_fake_auth.dart';

class ChatsListPage extends StatefulWidget {
  const ChatsListPage({super.key});

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  final _sb = Supabase.instance.client;
  late final String? myId;

  @override
  void initState() {
    super.initState();
    final real = _sb.auth.currentUser?.id;
    myId = (kDevNoAuth) ? kDevMyUid : real;
  }

  Future<List<Map<String, dynamic>>> _fetchChats() async {
    if (myId == null) return [];
    final data = await _sb
        .from('chats')
        .select()
        .contains('user_ids', [myId])
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// KİŞİYİ `people_search` view'ından oku (id, handle, name, avatar_url)
  Future<Map<String, dynamic>?> _fetchPerson(String uid) async {
    try {
      final res = await _sb
          .from('people_search')
          .select('id, handle, name, avatar_url')
          .eq('id', uid)
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
    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      body: myId == null
          ? const Center(child: Text('Giriş yapmalısın'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchChats(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Hata: ${snap.error}'));
                }
                final rows = snap.data ?? [];
                if (rows.isEmpty) {
                  return const Center(child: Text('Henüz mesaj yok'));
                }

                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final chat = rows[i];
                    final uids = List<String>.from(chat['user_ids'] ?? []);
                    final otherId = uids.firstWhere(
                      (e) => e != myId,
                      orElse: () => myId!,
                    );

                    final lastMessage = chat['last_message']?.toString() ?? '—';

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _fetchPerson(otherId),
                      builder: (context, p) {
                        final name =
                            (p.data?['name'] as String?) ??
                            (p.data?['handle'] as String?) ??
                            'Kullanıcı';
                        final avatarUrl = p.data?['avatar_url'] as String?;
                        final fallback = name.isNotEmpty
                            ? name.characters.first.toUpperCase()
                            : '?';

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Text(fallback)
                                : null,
                          ),
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatPage(otherUserId: otherId),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
