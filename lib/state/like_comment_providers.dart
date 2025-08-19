import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/post_repo.dart';

class PostRealtimeState {
  final int likes;
  final int comments;
  final bool isLiked;
  const PostRealtimeState({
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
  });

  PostRealtimeState copyWith({int? likes, int? comments, bool? isLiked}) {
    return PostRealtimeState(
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class PostRealtimeController extends StateNotifier<PostRealtimeState> {
  final String postId;
  StreamSubscription<int>? _likesSub;
  StreamSubscription<int>? _commentsSub;
  StreamSubscription<bool>? _likedSub;

  PostRealtimeController(this.postId) : super(const PostRealtimeState()) {
    _likesSub = PostRepo.likeCountStream(
      postId,
    ).listen((v) => state = state.copyWith(likes: v));
    _commentsSub = PostRepo.commentCountStream(
      postId,
    ).listen((v) => state = state.copyWith(comments: v));
    _likedSub = PostRepo.likedByMeStream(
      postId,
    ).listen((v) => state = state.copyWith(isLiked: v));
  }

  Future<void> toggleLikeOptimistic() async {
    final prev = state;
    final nextLiked = !state.isLiked;
    final nextLikes = nextLiked
        ? state.likes + 1
        : (state.likes > 0 ? state.likes - 1 : 0);
    state = state.copyWith(isLiked: nextLiked, likes: nextLikes);

    try {
      await PostRepo.toggleLike(postId);
    } catch (_) {
      state = prev; // rollback
    }
  }

  @override
  void dispose() {
    _likesSub?.cancel();
    _commentsSub?.cancel();
    _likedSub?.cancel();
    super.dispose();
  }
}

final postRealtimeProvider =
    StateNotifierProvider.family<
      PostRealtimeController,
      PostRealtimeState,
      String
    >((ref, postId) => PostRealtimeController(postId));
