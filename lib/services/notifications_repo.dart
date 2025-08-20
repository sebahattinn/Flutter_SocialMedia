import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationItem {
  final String id;
  final String type; // like | comment | follow
  final String actorId;
  final String? actorHandle;
  final String? actorName;
  final String? actorAvatar;
  final String? postId;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.actorId,
    required this.createdAt,
    this.actorHandle,
    this.actorName,
    this.actorAvatar,
    this.postId,
  });
}

class NotificationsRepo {
  static SupabaseClient get _s => Supabase.instance.client;

  // Supabase dart sürümünde in_() yoksa, filter('col','in','("a","b")') kullanacağız:
  static String _inList(Iterable<String> ids) {
    final quoted = ids.map((e) => '"$e"').join(',');
    return '($quoted)';
  }

  static Stream<List<NotificationItem>> streamForUser(
    String userId, {
    int limit = 100,
  }) {
    final controller = StreamController<List<NotificationItem>>();

    final sub = _s
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit)
        .listen((rows) async {
          try {
            final actorIds = <String>{};
            for (final r in rows) {
              final a = r['actor_id'] as String?;
              if (a != null) actorIds.add(a);
            }

            Map<String, Map<String, dynamic>> actors = {};
            if (actorIds.isNotEmpty) {
              final data = await _s
                  .from('profiles')
                  .select('id, handle, display_name, avatar_url')
                  // .in_('id', actorIds.toList())  // sende yok
                  .filter('id', 'in', _inList(actorIds)); // <-- alternatif

              for (final x in (data as List)) {
                actors[x['id'] as String] = Map<String, dynamic>.from(x);
              }
            }

            final list = rows.map<NotificationItem>((r) {
              final id = r['id'] as String;
              final type = r['type'] as String;
              final actorId = r['actor_id'] as String;
              final postId = r['post_id'] as String?;
              final createdAt = DateTime.parse(r['created_at'] as String);

              final a = actors[actorId];
              return NotificationItem(
                id: id,
                type: type,
                actorId: actorId,
                postId: postId,
                createdAt: createdAt,
                actorHandle: a?['handle'] as String?,
                actorName:
                    (a?['display_name'] as String?) ?? a?['handle'] as String?,
                actorAvatar: a?['avatar_url'] as String?,
              );
            }).toList();

            controller.add(list);
          } catch (_) {
            // fallback: en azından ham veriyi akıt
            final list = rows.map<NotificationItem>((r) {
              return NotificationItem(
                id: r['id'] as String,
                type: r['type'] as String,
                actorId: r['actor_id'] as String,
                postId: r['post_id'] as String?,
                createdAt: DateTime.parse(r['created_at'] as String),
              );
            }).toList();
            controller.add(list);
          }
        });

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }
}
