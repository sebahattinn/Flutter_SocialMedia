import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      12,
      (i) => 'User ${(i % 5) + 1} liked your post',
    );
    return CustomScrollView(
      slivers: [
        const SliverAppBar(floating: true, snap: true, title: Text('Alerts')),
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (_, i) => ListTile(
            leading: const CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/80?img=12'),
            ),
            title: Text(items[i]),
            subtitle: const Text('just now'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }
}
