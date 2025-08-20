import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/notifications_repo.dart';
import '../../services/post_repo.dart';
import '../widgets/avatar.dart';

final _notifsProvider = StreamProvider<List<NotificationItem>>((ref) {
  return NotificationsRepo.streamForUser(PostRepo.devUserId);
});

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_notifsProvider);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(floating: true, snap: true, title: Text('Alerts')),
        async.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to load notifications: $e'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No notifications yet')),
                ),
              );
            }

            return SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) {
                final n = items[i];
                final title = _titleFor(n);
                final time = _formatWhen(n.createdAt);

                return ListTile(
                  leading: Avatar(url: n.actorAvatar ?? '', size: 48),
                  title: Text(title, maxLines: 2),
                  subtitle: Text(time),
                  onTap: () {
                    // İstersen post detayına gidebilirsin (n.postId varsa).
                  },
                  trailing: const Icon(Icons.chevron_right),
                );
              },
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  String _titleFor(NotificationItem n) {
    final who = n.actorName ?? '@${n.actorHandle ?? n.actorId.substring(0, 6)}';
    switch (n.type) {
      case 'like':
        return '$who liked your post';
      case 'comment':
        return '$who commented on your post';
      case 'follow':
        return '$who started following you';
      default:
        return '$who sent an update';
    }
  }

  String _formatWhen(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';

    final y = DateTime(now.year, now.month, now.day - 1);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == y) {
      final hh = _two(dt.hour);
      final mm = _two(dt.minute);
      return 'yesterday at $hh:$mm';
    }
    final hh = _two(dt.hour);
    final mm = _two(dt.minute);
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} $hh:$mm';
  }

  String _two(int x) => x < 10 ? '0$x' : '$x';
}
