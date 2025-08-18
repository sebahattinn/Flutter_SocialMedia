import 'user.dart';

class Post {
  final String id;
  final AppUser author;
  final String text;

  /// Çoklu görsel desteği
  final List<String> imageUrls;

  /// Tek video URL’i (opsiyonel)
  final String? videoUrl;

  final DateTime createdAt;
  final int likes;
  final int comments;
  final int shares;

  const Post({
    required this.id,
    required this.author,
    this.text = '',
    this.imageUrls = const [],
    this.videoUrl,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
  });

  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasVideo => (videoUrl ?? '').isNotEmpty;
}
