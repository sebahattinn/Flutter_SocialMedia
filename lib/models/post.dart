import 'user.dart';

class Post {
  final String id;
  final AppUser author;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  int likes;
  int comments;
  int shares;

  Post({
    required this.id,
    required this.author,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
  });
}
