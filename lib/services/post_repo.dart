import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dev_fake_auth.dart'; // kDevMyUid

class PostRepo {
  static SupabaseClient get _s => Supabase.instance.client;

  /// 🔑 Uygulamanın HER YERİNDE kullanacağımız aktif kullanıcı ID'si.
  /// - Gerçek auth varsa: auth.currentUser.id
  /// - Dev modda: kDevMyUid
  static String get devUserId => _s.auth.currentUser?.id ?? kDevMyUid;

  // UUID helper
  static final RegExp _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static bool isUuid(String s) => _uuidRe.hasMatch(s);

  // small debug helper
  static void _log(String msg) {
    const debug = true;
    if (debug) print('[PostRepo] $msg');
  }

  // -------- Create --------
  static Future<String> createPostDev({
    String? text,
    List<String> imageUrls = const [],
    String? videoUrl,
    String? authorId,
  }) async {
    final uid = authorId ?? devUserId;
    _log(
      'createPostDev(authorId=$uid, images=${imageUrls.length}, hasVideo=${videoUrl != null})',
    );

    final inserted = await _s
        .from('posts')
        .insert({
          // Şeman: author_id
          'author_id': uid,
          if (text != null && text.isNotEmpty)
            'text': text, // content/text/caption
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final String postId = inserted['id'] as String;
    _log('post inserted id=$postId');

    // tüm medya post_media'da
    final List<Map<String, dynamic>> mediaPayload = [];

    for (int i = 0; i < imageUrls.length; i++) {
      mediaPayload.add({
        'post_id': postId,
        'kind': 'image',
        'url': imageUrls[i],
        'order_index': i,
      });
    }

    if (videoUrl != null && videoUrl.isNotEmpty) {
      mediaPayload.add({
        'post_id': postId,
        'kind': 'video',
        'url': videoUrl,
        'order_index': imageUrls.length,
      });
    }

    if (mediaPayload.isNotEmpty) {
      _log('inserting media ${mediaPayload.length} item(s)');
      await _s.from('post_media').insert(mediaPayload);
    }

    return postId;
  }

  // -------- Feed (DB) --------
  static Stream<List<Map<String, dynamic>>> feedStream({int limit = 20}) {
    _log('feedStream(limit=$limit)');
    return _s
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map((rows) => rows);
  }

  // -------- Post Media (url/kind/order_index) --------
  static Future<List<Map<String, dynamic>>> postMedia(String postId) async {
    _log('postMedia($postId)');
    final rows = await _s
        .from('post_media')
        .select('*')
        .eq('post_id', postId)
        .order('order_index', ascending: true);

    final list = (rows as List)
        .map<Map<String, dynamic>>((m) {
          final r = Map<String, dynamic>.from(m);
          final url = (r['url'] ?? '') as String;
          final kind = (r['kind'] ?? 'image') as String;
          final orderIndex = (r['order_index'] ?? 0) as int;
          return {
            'media_url': url,
            'media_type': kind,
            'order_index': orderIndex,
            'created': r['created_at'] ?? DateTime.now().toIso8601String(),
          };
        })
        .where((m) => (m['media_url'] as String).isNotEmpty)
        .toList();

    return list;
  }

  // -------- Get posts by author (for profile) --------
  static Future<List<Map<String, dynamic>>> getPostsByAuthor(
    String authorId, {
    int limit = 20,
  }) async {
    _log('getPostsByAuthor($authorId, limit=$limit)');
    final rows = await _s
        .from('posts')
        .select('*')
        .eq('author_id', authorId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  // -------- Streams (metrics) --------
  static Stream<int> likesCount(String postId) {
    if (!isUuid(postId)) return Stream.value(0);
    return _s
        .from('post_likes')
        .stream(primaryKey: ['post_id', 'user_id'])
        .eq('post_id', postId)
        .map((rows) => rows.length);
  }

  static Stream<int> commentsCount(String postId) {
    if (!isUuid(postId)) return Stream.value(0);
    return _s
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((rows) => rows.length);
  }

  /// Realtime tek filtre limiti: user_id ile filtre + client-side postId check
  static Stream<bool> isLikedByMe(String postId, {String? userId}) {
    if (!isUuid(postId)) return Stream.value(false);
    final uid = userId ?? devUserId;
    return _s
        .from('post_likes')
        .stream(primaryKey: ['post_id', 'user_id'])
        .eq('user_id', uid)
        .map((rows) => rows.any((r) => r['post_id'] == postId));
  }

  // -------- Actions --------
  static Future<void> toggleLike(String postId, {String? userId}) async {
    if (!isUuid(postId)) return;
    final uid = userId ?? devUserId;

    final existing = await _s
        .from('post_likes')
        .select('post_id')
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existing != null) {
      await _s
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
    } else {
      await _s.from('post_likes').insert({
        'post_id': postId,
        'user_id': uid,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static Stream<List<Map<String, dynamic>>> commentsStream(String postId) {
    if (!isUuid(postId)) return Stream.value(const []);
    return _s
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((rows) {
          rows.sort((a, b) {
            final da = DateTime.parse(a['created_at'] as String);
            final db = DateTime.parse(b['created_at'] as String);
            return da.compareTo(db);
          });
          return rows;
        });
  }

  static Future<void> addComment(
    String postId,
    String text, {
    String? userId,
  }) async {
    if (!isUuid(postId)) return;
    final uid = userId ?? devUserId;
    await _s.from('comments').insert({
      'post_id': postId,
      'author_id': uid,
      'text': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // -------- Delete (prefers RPC; falls back to client cascade) --------
  static Future<void> deletePost(String postId, {String? userId}) async {
    if (!isUuid(postId)) {
      _log('deletePost invalid uuid: $postId');
      throw Exception('invalid post id');
    }
    final uid = userId ?? devUserId;
    _log('deletePost(postId=$postId, uid=$uid)');

    final post = await _s
        .from('posts')
        .select('id, author_id')
        .eq('id', postId)
        .maybeSingle();
    if (post == null) {
      _log('post not found');
      throw Exception('post not found');
    }
    if (post['author_id'] != uid) {
      _log('not owner: author_id=${post['author_id']} uid=$uid');
      throw Exception('not owner');
    }

    try {
      _log('trying RPC delete_post_cascade...');
      final rpcResult = await _s.rpc(
        'delete_post_cascade',
        params: {'p_post_id': postId, 'p_author_id': uid},
      );
      if (rpcResult is bool && rpcResult == true) {
        _log('RPC delete ok');
        return;
      } else {
        _log('RPC returned non-true ($rpcResult), fallback...');
      }
    } on PostgrestException catch (e) {
      _log('RPC failed (${e.code} ${e.message}), fallback...');
    }

    try {
      _log('client cascade: children -> post');
      await _s.from('post_likes').delete().eq('post_id', postId);
      await _s.from('comments').delete().eq('post_id', postId);
      await _s.from('post_media').delete().eq('post_id', postId);

      final res = await _s
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('author_id', uid)
          .select('id')
          .maybeSingle();

      if (res == null) {
        _log('delete returned null');
        throw Exception('delete failed (unknown)');
      }
      _log('client cascade ok');
    } on PostgrestException catch (e) {
      _log('client cascade failed: ${e.code} ${e.message}');
      throw Exception('delete blocked: ${e.message}');
    }
  }

  // -------- Aliases --------
  static Stream<bool> likedByMeStream(String postId) => isLikedByMe(postId);
  static Stream<int> likeCountStream(String postId) => likesCount(postId);
  static Stream<int> commentCountStream(String postId) => commentsCount(postId);
}
