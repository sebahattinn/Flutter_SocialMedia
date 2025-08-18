import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/follow_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // DEMO IDs — must match your Supabase rows
    const me = '00000000-0000-0000-0000-000000000001';
    const target = '00000000-0000-0000-0000-000000000002';

    final provider = followControllerProvider(
      const FollowIds(me: me, target: target),
    );
    final s = ref.watch(provider);
    final c = ref.read(provider.notifier);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(floating: true, snap: true, title: Text('Profile')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 46,
                  backgroundImage: NetworkImage(
                    'https://picsum.photos/seed/aybars/200/200',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aybars Mete',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const Text('@aybars', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                const Text(
                  'Building things. Coffee, code, and clean design.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stat('Followers', _compact(s.followers)),
                    const SizedBox(width: 24),
                    _stat('Following', _compact(s.following)),
                  ],
                ),
                const SizedBox(height: 20),
                s.isFollowing
                    ? OutlinedButton.icon(
                        onPressed: c.toggleFollow,
                        icon: const Icon(Icons.person_remove),
                        label: const Text('Unfollow'),
                      )
                    : FilledButton.icon(
                        onPressed: c.toggleFollow,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Follow'),
                      ),
                if (s.loading == true)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (s.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${s.error}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.grey)),
    ],
  );

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
