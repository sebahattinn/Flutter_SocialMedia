import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class CommentsRepo {
  static const devUserId = '00000000-0000-0000-0000-000000000001';
  static SupabaseClient get _s => SupabaseService.client;

  static Future<List<Map<String, dynamic>>> listForPost(String postId) async {
    final rows = await _s
        .from('comments')
        .select('id, text, author_id, created_at')
        .eq('post_id', postId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> add(String postId, String text) async {
    await _s.from('comments').insert({
      'post_id': postId,
      'author_id': devUserId,
      'text': text.trim(),
    });
  }
}
