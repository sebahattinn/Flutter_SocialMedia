import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_repo.dart'; // PostRepo.devUserId

class FollowRepo {
  static SupabaseClient get _s => Supabase.instance.client;

  static Stream<bool> isFollowing(String targetId, {String? userId}) {
    final uid = userId ?? PostRepo.devUserId;
    return _s
        .from('follows')
        .stream(primaryKey: ['follower', 'followee'])
        .eq('follower', uid)
        .map((rows) => rows.any((r) => r['followee'] == targetId));
  }

  static Future<void> toggle(String targetId, {String? userId}) async {
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
      await _s.from('follows').insert({
        'follower': uid,
        'followee': targetId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static Stream<int> followersCount(String userId) {
    return _s
        .from('follows')
        .stream(primaryKey: ['follower', 'followee'])
        .eq('followee', userId)
        .map((rows) => rows.length);
  }

  static Stream<int> followingCount(String userId) {
    return _s
        .from('follows')
        .stream(primaryKey: ['follower', 'followee'])
        .eq('follower', userId)
        .map((rows) => rows.length);
  }
}
