import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    'https://i.pravatar.cc/150?img=32',
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
                  children: const [
                    _Stat(label: 'Posts', value: '128'),
                    SizedBox(width: 24),
                    _Stat(label: 'Followers', value: '8.4K'),
                    SizedBox(width: 24),
                    _Stat(label: 'Following', value: '412'),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Follow'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Placeholder grid
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 18,
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                'https://picsum.photos/seed/p$i/600/600',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
