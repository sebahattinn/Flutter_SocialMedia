import 'package:flutter/material.dart';
import '../../../models/user.dart';
import 'avatar.dart';

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
            return Column(
              children: [
                Stack(
                  children: [
                    const Avatar(
                      url: 'https://i.pravatar.cc/150?img=64',
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
                          child: Icon(Icons.add, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Your Story', style: TextStyle(fontSize: 12)),
              ],
            );
          }
          final u = users[i - 1];
          return Column(
            children: [
              Avatar(url: u.avatarUrl, size: 56, ring: true),
              const SizedBox(height: 6),
              Text(u.handle, style: const TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );
  }
}
