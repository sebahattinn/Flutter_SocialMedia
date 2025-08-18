import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_media_app/features/chat/chat_page.dart' show ChatPage;
import 'package:social_media_app/features/widgets/composer_button.dart';
import 'package:social_media_app/features/widgets/post_card.dart';
import 'package:social_media_app/features/widgets/story_strip.dart';
import 'package:social_media_app/models/mock_data.dart' as mock;
import '../../state/feed_controller.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(feedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text(
            'SociaLink',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: isDark ? Colors.black : Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ChatPage())),
            ),
          ],
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: ComposerButton()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(child: StoryStrip(users: mock.users)),
        SliverList.separated(
          itemCount: items.length,
          itemBuilder: (_, i) => PostCard(post: items[i]),
          separatorBuilder: (_, __) => const SizedBox(height: 4),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}
