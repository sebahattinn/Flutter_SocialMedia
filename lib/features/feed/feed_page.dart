import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import '../widgets/story_strip.dart';
import '../widgets/post_card.dart';
import '../widgets/composer_button.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomScrollView(
      slivers: [
        // Minimal top bar; child controls its own UI
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text(
            'SociaLink',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: isDark ? Colors.black : Colors.white,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: ComposerButton()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(child: StoryStrip(users: users)),
        SliverList.separated(
          itemCount: posts.length,
          itemBuilder: (_, i) => PostCard(post: posts[i]),
          separatorBuilder: (_, __) => const SizedBox(height: 4),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}
