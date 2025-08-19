import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostRepo {
  static SupabaseClient get _s => Supabase.instance.client;

  // DEMO user (auth gelene kadar)
  static const String devUserId = '00000000-0000-0000-0000-000000000001';

  // UUID helper
  static final RegExp _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static bool isUuid(String s) => _uuidRe.hasMatch(s);

  // -------- Create --------
  static Future<String> createPostDev({
    String? text,
    List<String> imageUrls = const [],
    String? videoUrl,
    String? authorId, // istersen farklı kullanıcıyla test etmek için
  }) async {
    final inserted = await _s
        .from('posts')
        .insert({
          'author_id': authorId ?? devUserId,
          if (text != null && text.isNotEmpty) 'text': text,
          if (videoUrl != null && videoUrl.isNotEmpty) 'video_url': videoUrl,
        })
        .select('id')
        .single();

    final String postId = inserted['id'] as String;

    if (imageUrls.isNotEmpty) {
      await _s
          .from('post_media')
          .insert(
            imageUrls.map(
              (u) => {'post_id': postId, 'media_url': u, 'media_type': 'image'},
            ),
          );
    }

    if (videoUrl != null && videoUrl.isNotEmpty) {
      await _s.from('post_media').insert({
        'post_id': postId,
        'media_url': videoUrl,
        'media_type': 'video',
      });
    }

    return postId;
  }

  // -------- Feed (DB) --------
  static Stream<List<Map<String, dynamic>>> feedStream({int limit = 20}) {
    return _s
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map((rows) => rows);
  }

  // -------- Post Media (Normalized & client-side sort) --------
  static Future<List<Map<String, dynamic>>> postMedia(String postId) async {
    final rows = await _s
        .from('post_media')
        .select('*') // esnek al (kolon isimleri farklı olabilir)
        .eq(
          'post_id',
          postId,
        ); // DB tarafında order yok (kolon eksikse patlamasın)

    // Hepsini {media_url, media_type, created} biçimine normalize et
    final list = (rows as List)
        .map<Map<String, dynamic>>((m) {
          final r = Map<String, dynamic>.from(m);

          final url =
              (r['media_url'] ?? r['url'] ?? r['path'] ?? r['file_url'] ?? '')
                  as String;

          final type =
              (r['media_type'] ??
                      r['type'] ??
                      (url.toLowerCase().endsWith('.mp4') ? 'video' : 'image'))
                  as String;

          // Farklı timestamp kolonlarından birini bul (opsiyonel)
          final created =
              r['created_at'] ??
              r['inserted_at'] ??
              r['uploaded_at'] ??
              r['created'] ??
              r['timestamp'];

          return {
            'media_url': url,
            'media_type': type,
            'created': created, // client-side sort için tutuluyor
          };
        })
        .where((m) => (m['media_url'] as String).isNotEmpty)
        .toList();

    // Client-side sırala (timestamp varsa)
    list.sort((a, b) {
      final x = a['created'], y = b['created'];
      if (x == null || y == null) return 0;
      final dx = x is String ? DateTime.tryParse(x) : x as DateTime?;
      final dy = y is String ? DateTime.tryParse(y) : y as DateTime?;
      if (dx == null || dy == null) return 0;
      return dx.compareTo(dy);
    });

    return list;
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
      await _s.from('post_likes').insert({'post_id': postId, 'user_id': uid});
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
    });
  }

  // -------- Aliases --------
  static Stream<bool> likedByMeStream(String postId) => isLikedByMe(postId);
  static Stream<int> likeCountStream(String postId) => likesCount(postId);
  static Stream<int> commentCountStream(String postId) => commentsCount(postId);
}
