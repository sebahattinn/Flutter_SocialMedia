import 'package:flutter/material.dart';
import '../../../../core/spacing.dart';
import '../../../models/post.dart';
import 'avatar.dart';
import 'action_bar.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Avatar(url: post.author.avatarUrl, ring: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '@${post.author.handle} • ${_timeAgo(post.createdAt)}',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ),
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.text,
                style: const TextStyle(fontSize: 15, height: 1.35),
              ),
            ),
          if (post.imageUrl != null) ...[
            gap12,
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: radius.bottomLeft,
                bottomRight: radius.bottomRight,
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(post.imageUrl!, fit: BoxFit.cover),
              ),
            ),
          ] else
            gap12,
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: ActionBar(
              likes: post.likes,
              comments: post.comments,
              shares: post.shares,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
