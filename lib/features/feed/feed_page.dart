// lib/features/feed/feed_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_media_app/features/chat/chat_page.dart' show ChatPage;
import 'package:social_media_app/features/widgets/composer_button.dart';
import 'package:social_media_app/features/widgets/post_card.dart';
import 'package:social_media_app/features/widgets/story_strip.dart';
import '../../state/feed_controller.dart';
import '../../models/mock_data.dart' as mock; // sadece story için kalabilir

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feed = ref.watch(dbFeedProvider);

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

        // İstersen StoryStrip’i de DB’ye taşıyıncaya kadar mock’tan bırak
        SliverToBoxAdapter(child: StoryStrip(users: mock.users)),

        feed.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Feed yüklenemedi: $e'),
            ),
          ),
          data: (items) => SliverList.separated(
            itemCount: items.length,
            itemBuilder: (_, i) => PostCard(post: items[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 4),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}
