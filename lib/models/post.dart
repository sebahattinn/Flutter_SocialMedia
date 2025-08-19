import 'package:social_media_app/models/user.dart';

class Post {
  final String id;
  final AppUser author;

  final String text;
  final List<String> imageUrls; // non-nullable, default []
  final String? videoUrl;

  final DateTime createdAt;
  final int likes;
  final int comments;
  final int shares;

  const Post({
    required this.id,
    required this.author,
    this.text = '',
    this.imageUrls = const [], // <-- önemli
    this.videoUrl,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
  });

  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
}
