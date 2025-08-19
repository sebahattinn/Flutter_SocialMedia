import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_media_app/features/widgets/comments_sheet.dart';

import '../../../state/like_comment_providers.dart'; // postRealtimeProvider burada

class ActionBar extends ConsumerWidget {
  final String postId;
  final int shares; // şimdilik mock

  const ActionBar({super.key, required this.postId, this.shares = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pr = ref.watch(
      postRealtimeProvider(postId),
    ); // likes, comments, isLiked

    return Row(
      children: [
        IconButton(
          onPressed: () => ref
              .read(postRealtimeProvider(postId).notifier)
              .toggleLikeOptimistic(),
          icon: Icon(
            pr.isLiked ? Icons.favorite : Icons.favorite_border,
            color: pr.isLiked ? Colors.redAccent : null,
          ),
        ),
        Text('${pr.likes}'),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CommentsSheet(postId: postId),
            );
          },
          icon: const Icon(Icons.comment_outlined),
        ),
        Text('${pr.comments}'),
        const Spacer(),
        const Icon(Icons.share_outlined),
        Text('$shares'),
      ],
    );
  }
}
