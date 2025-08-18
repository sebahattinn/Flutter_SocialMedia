import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../models/mock_data.dart' as mock;

final feedProvider = StateNotifierProvider<FeedController, List<Post>>(
  (ref) => FeedController(),
);

class FeedController extends StateNotifier<List<Post>> {
  FeedController() : super(List<Post>.from(mock.posts));

  void addLocalPost(Post p) {
    state = [p, ...state];
  }
}
