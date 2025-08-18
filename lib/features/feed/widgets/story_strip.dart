import 'package:flutter/material.dart';
import 'package:social_media_app/features/widgets/avatar.dart';
import '../../../models/user.dart';
//import '../../widgets/avatar.dart';
import 'package:social_media_app/features/stories/story_viewer.dart';

class StoryStrip extends StatelessWidget {
  final List<AppUser> users;
  const StoryStrip({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: users.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (i == 0) {
            // "Your Story"
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StoryViewer(
                      username: 'You',
                      avatarUrl: 'https://picsum.photos/id/1027/200/200',
                      images: [
                        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1500&q=80&auto=format&fit=crop',
                        'https://images.unsplash.com/photo-1501973801540-537f08ccae7b?w=1500&q=80&auto=format&fit=crop',
                      ],
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Stack(
                    children: [
                      const Avatar(
                        url: 'https://picsum.photos/id/1027/200/200',
                        size: 56,
                      ),
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
                  const Text('Your Story', style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          }

          // Other users
          final u = users[i - 1];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoryViewer(
                    username: u.handle,
                    avatarUrl: u.avatarUrl,
                    images: const [
                      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1500&q=80&auto=format&fit=crop',
                      'https://images.unsplash.com/photo-1499084732479-de2c02d45fc4?w=1500&q=80&auto=format&fit=crop',
                    ],
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Avatar(url: u.avatarUrl, size: 56, ring: true),
                const SizedBox(height: 6),
                Text(u.handle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}
