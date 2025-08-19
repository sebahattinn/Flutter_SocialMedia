// lib/state/feed_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_repo.dart';

/// Realtime DB feed -> List<Post>
final dbFeedProvider = StreamProvider<List<Post>>((ref) async* {
  await for (final rows in PostRepo.feedStream(limit: 50)) {
    final list = <Post>[];

    for (final r in rows) {
      final id = r['id'] as String;
      final text = (r['text'] ?? '') as String;
      final createdAt = DateTime.parse(r['created_at'] as String);

      // -------------------------
      // Medya kayıtlarını çek ve normalize et
      // -------------------------
      final media = await PostRepo.postMedia(id);
      final imageUrls = <String>[];
      String? videoUrl;

      for (final m in media) {
        final t = (m['media_type'] ?? '') as String;
        final u = (m['media_url'] ?? '') as String;
        if (t == 'image') imageUrls.add(u);
        if (t == 'video') videoUrl = u;
      }

      // -------------------------
      // Şimdilik tek dev kullanıcıyla test
      // -------------------------
      final authorId = (r['author_id'] ?? PostRepo.devUserId) as String;
      final author = AppUser(
        id: authorId,
        handle: 'user1',
        name: 'User 1',
        avatarUrl: '',
        bio: '',
      );

      // -------------------------
      // Post objesini oluştur
      // -------------------------
      list.add(
        Post(
          id: id,
          author: author,
          text: text,
          imageUrls: imageUrls,
          videoUrl: videoUrl,
          createdAt: createdAt,
        ),
      );
    }

    yield list;
  }
});
