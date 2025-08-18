import 'package:flutter/material.dart';
import 'package:social_media_app/features/widgets/avatar.dart';
import '../../../models/user.dart';
import 'package:social_media_app/features/stories/story_viewer.dart';

class StoryStrip extends StatelessWidget {
  final List<AppUser> users;
  const StoryStrip({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    // Kişi başına TEK görsel olacak şekilde story listesi
    final stories = <Story>[
      const Story(
        username: 'You',
        avatarUrl: 'https://picsum.photos/seed/me/200/200',
        images: [
          // tek görsel
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1500&q=80&auto=format&fit=crop',
        ],
      ),
      for (final u in users)
        Story(
          username: u.handle,
          avatarUrl: u.avatarUrl,
          images: [
            // tek görsel: herkes için farklı seed, CORS sorunsuz
            'https://picsum.photos/seed/${u.id}/1200/2000',
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
                  stories: stories, // tüm kişiler
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
