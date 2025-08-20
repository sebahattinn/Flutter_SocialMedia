import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../current_user.dart'; // currentUidProvider
import 'package:social_media_app/state/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, this.userId});
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUidProvider);
    final uid = userId ?? me;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Giriş yapmalısın')));
    }
    return _ProfileContent(uid: uid, ref: ref);
  }
}

class _ProfileContent extends StatefulWidget {
  const _ProfileContent({required this.uid, required this.ref});
  final String uid;
  final WidgetRef ref;

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  final _sb = Supabase.instance.client;
  late Future<
    ({
      Map<String, dynamic>? person,
      List<Map<String, dynamic>> posts,
      int followers,
      int following,
    })
  >
  _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<
    ({
      Map<String, dynamic>? person,
      List<Map<String, dynamic>> posts,
      int followers,
      int following,
    })
  >
  _load() async {
    try {
      final personRes = await _sb
          .from('people_search')
          .select('id, handle, name, avatar_url')
          .eq('id', widget.uid)
          .maybeSingle();
      final person = personRes == null
          ? null
          : Map<String, dynamic>.from(personRes as Map);

      final postsRes = await _sb
          .from('posts')
          .select()
          .eq('author_id', widget.uid)
          .order('created_at', ascending: false);
      final posts = (postsRes as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final followersRes = await _sb
          .from('follows')
          .select('follower')
          .eq('followee', widget.uid);
      final followingRes = await _sb
          .from('follows')
          .select('followee')
          .eq('follower', widget.uid);

      return (
        person: person,
        posts: posts,
        followers: (followersRes as List).length,
        following: (followingRes as List).length,
      );
    } catch (e) {
      debugPrint('Profile load error: $e');
      return (
        person: null,
        posts: <Map<String, dynamic>>[],
        followers: 0,
        following: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          FutureBuilder<
            ({
              Map<String, dynamic>? person,
              List<Map<String, dynamic>> posts,
              int followers,
              int following,
            })
          >(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Yüklenemedi: ${snap.error}'));
              }

              final person = snap.data!.person;
              final posts = snap.data!.posts;
              final followers = snap.data!.followers;
              final following = snap.data!.following;

              final displayName =
                  (person?['name'] as String?) ??
                  (person?['handle'] as String?) ??
                  'User';
              final handle = person?['handle'] as String? ?? '';
              final avatarUrl = person?['avatar_url'] as String?;
              final initial = displayName.isNotEmpty
                  ? displayName.characters.first.toUpperCase()
                  : '?';

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: Text(displayName),
                    actions: [
                      IconButton(
                        onPressed: () {
                          widget.ref
                              .read(authControllerProvider.notifier)
                              .logout();
                        },
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage:
                                (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Text(
                                    initial,
                                    style: const TextStyle(fontSize: 28),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (handle.isNotEmpty)
                                  Text(
                                    '@$handle',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _Stat(label: 'Posts', value: posts.length),
                                    const SizedBox(width: 16),
                                    _Stat(label: 'Followers', value: followers),
                                    const SizedBox(width: 16),
                                    _Stat(label: 'Following', value: following),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: Divider(height: 1)),
                  SliverList.separated(
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = posts[i];
                      final text =
                          (p['content'] ?? p['text'] ?? p['caption'] ?? '')
                              .toString();
                      final created = (p['created_at'] ?? '').toString();
                      return ListTile(
                        title: Text(text.isEmpty ? '—' : text),
                        subtitle: Text(created),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              );
            },
          ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$value', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
