import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class PostActions {
  // DEV: auth yokken sabit user id
  static const devUserId = '00000000-0000-0000-0000-000000000001';
  static SupabaseClient get _s => SupabaseService.client;

  static Future<bool> hasLiked(String postId) async {
    final rows = await _s
        .from('post_likes')
        .select('post_id')
        .eq('post_id', postId)
        .eq('user_id', devUserId);
    return rows.isNotEmpty;
  }

  static Future<void> like(String postId) async {
    await _s.from('post_likes').insert({
      'user_id': devUserId,
      'post_id': postId,
    });
  }

  static Future<void> unlike(String postId) async {
    await _s
        .from('post_likes')
        .delete()
        .eq('user_id', devUserId)
        .eq('post_id', postId);
  }

  static Future<void> toggleLike(String postId) async {
    if (await hasLiked(postId)) {
      await unlike(postId);
    } else {
      await like(postId);
    }
  }
}
