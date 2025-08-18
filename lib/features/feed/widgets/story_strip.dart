import 'package:flutter/material.dart';
import 'package:social_media_app/features/widgets/avatar.dart';
import '../../../models/user.dart';
import 'package:social_media_app/features/stories/story_viewer.dart';

class StoryStrip extends StatelessWidget {
  final List<AppUser> users;
  const StoryStrip({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    // 1) "You" + diğer kullanıcılar -> Story listesine dönüştür
    final stories = <Story>[
      const Story(
        username: 'You',
        avatarUrl: 'https://picsum.photos/seed/me/200/200',
        images: [
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1500&q=80&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1501973801540-537f08ccae7b?w=1500&q=80&auto=format&fit=crop',
        ],
      ),
      for (final u in users)
        Story(
          username: u.handle,
          avatarUrl: u.avatarUrl,
          images: const [
            'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1500&q=80&auto=format&fit=crop',
            'https://images.unsplash.com/photo-1499084732479-de2c02d45fc4?w=1500&q=80&auto=format&fit=crop',
          ],
        ),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = stories[i];

          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoryViewer(
                  stories: stories,
                  initialIndex: i, // tıklanan kişi ile aç
                ),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Avatar(url: s.avatarUrl, size: 56, ring: i != 0),
                    if (i == 0)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black,
                            child: Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  i == 0 ? 'Your Story' : s.username,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
