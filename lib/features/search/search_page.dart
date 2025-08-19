import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/follow_repo.dart';
import '../../services/post_repo.dart';
import '../widgets/avatar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _q = TextEditingController();
  Timer? _deb;
  bool _loading = false;
  List<Map<String, dynamic>> _rows = [];

  @override
  void dispose() {
    _deb?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _rows = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('people_search') // <--- birleşik view
          .select('id, handle, name, avatar_url')
          .or('handle.ilike.%$q%,name.ilike.%$q%')
          .limit(25);

      setState(() {
        _rows = (data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(floating: true, snap: true, title: Text('Search')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _q,
              onChanged: (v) {
                _deb?.cancel();
                _deb = Timer(const Duration(milliseconds: 350), () {
                  _runSearch(v);
                });
              },
              decoration: InputDecoration(
                hintText: 'Search people…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_rows.isEmpty && _q.text.trim().isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: Text('No results')),
            ),
          )
        else
          SliverList.separated(
            itemCount: _rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = _rows[i];
              final id = r['id'] as String;
              final handle = r['handle'] as String? ?? '';
              final name = r['name'] as String? ?? handle;
              final avatar = r['avatar_url'] as String?;
              final isMe = id == PostRepo.devUserId;

              return ListTile(
                leading: Avatar(url: avatar ?? '', size: 44),
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '@$handle',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                trailing: isMe
                    ? const SizedBox.shrink()
                    : StreamBuilder<bool>(
                        stream: FollowRepo.isFollowing(id),
                        builder: (context, snap) {
                          final following = snap.data ?? false;
                          return OutlinedButton(
                            onPressed: () async {
                              try {
                                await FollowRepo.toggle(id);
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            },
                            child: Text(following ? 'Following' : 'Follow'),
                          );
                        },
                      ),
                onTap: () {
                  // TODO: profil sayfasına git
                },
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
