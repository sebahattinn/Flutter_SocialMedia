import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_repo.dart'; // devUserId + isUuid için

class FollowRepo {
  static SupabaseClient get _s => Supabase.instance.client;

  /// Takip ediyor muyum? (realtime – tek filtre limiti nedeniyle client-side check)
  static Stream<bool> isFollowing(String targetId, {String? userId}) {
    if (!PostRepo.isUuid(targetId)) return Stream.value(false);
    final uid = userId ?? PostRepo.devUserId;

    return _s
        .from('follows')
        .stream(primaryKey: ['follower', 'followee'])
        .eq('follower', uid)
        .map((rows) => rows.any((r) => r['followee'] == targetId));
  }

  /// Toggle follow/unfollow (sende kolonlar: follower, followee)
  static Future<void> toggle(String targetId, {String? userId}) async {
    if (!PostRepo.isUuid(targetId)) return;
    final uid = userId ?? PostRepo.devUserId;
    if (uid == targetId) return;

    final existing = await _s
        .from('follows')
        .select('follower')
        .eq('follower', uid)
        .eq('followee', targetId)
        .maybeSingle();

    if (existing != null) {
      await _s
          .from('follows')
          .delete()
          .eq('follower', uid)
          .eq('followee', targetId);
    } else {
      await _s.from('follows').insert({'follower': uid, 'followee': targetId});
    }
  }
}
