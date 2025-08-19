// lib/state/feed_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_repo.dart';

/// Realtime DB feed -> List<Post>
final dbFeedProvider = StreamProvider<List<Post>>((ref) async* {
  await for (final rows in PostRepo.feedStream(limit: 50)) {
    final list = await _convertRowsToPosts(rows);
    yield list;
  }
});

/// Profile posts provider - gets posts by specific author
final profilePostsProvider = FutureProvider.family<List<Post>, String>((
  ref,
  authorId,
) async {
  final rows = await PostRepo.getPostsByAuthor(authorId, limit: 50);
  return await _convertRowsToPosts(rows);
});

/// Helper function to convert raw DB rows to Post objects
Future<List<Post>> _convertRowsToPosts(List<Map<String, dynamic>> rows) async {
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
    // Author bilgisini al
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

  return list;
}
