import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/post_actions.dart';

class PostRealtimeState {
  final int likes;
  final int comments;
  final bool isLiked;
  final bool loading;
  const PostRealtimeState({
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.loading = true,
  });

  PostRealtimeState copyWith({
    int? likes,
    int? comments,
    bool? isLiked,
    bool? loading,
  }) => PostRealtimeState(
    likes: likes ?? this.likes,
    comments: comments ?? this.comments,
    isLiked: isLiked ?? this.isLiked,
    loading: loading ?? this.loading,
  );
}

class PostRealtimeController extends StateNotifier<PostRealtimeState> {
  final String postId;
  final s = SupabaseService.client;
  RealtimeChannel? _likesChan;
  RealtimeChannel? _commentsChan;

  PostRealtimeController(this.postId) : super(const PostRealtimeState()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _refreshCounts();
    await _refreshIsLiked();

    _likesChan = s
        .channel('public:post_likes:$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_likes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: postId,
          ),
          callback: (_) => _refreshCounts(onlyLikes: true),
        )
        .subscribe();

    _commentsChan = s
        .channel('public:comments:$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: postId,
          ),
          callback: (_) => _refreshCounts(onlyComments: true),
        )
        .subscribe();

    state = state.copyWith(loading: false);
  }

  Future<void> _refreshCounts({
    bool onlyLikes = false,
    bool onlyComments = false,
  }) async {
    if (!onlyComments) {
      final likeRows = await s
          .from('post_likes')
          .select('post_id')
          .eq('post_id', postId);
      state = state.copyWith(likes: likeRows.length);
    }
    if (!onlyLikes) {
      final commentRows = await s
          .from('comments')
          .select('post_id')
          .eq('post_id', postId);
      state = state.copyWith(comments: commentRows.length);
    }
  }

  Future<void> _refreshIsLiked() async {
    final liked = await PostActions.hasLiked(postId);
    state = state.copyWith(isLiked: liked);
  }

  Future<void> toggleLikeOptimistic() async {
    final wasLiked = state.isLiked;
    final newLiked = !wasLiked;
    final newLikes = wasLiked ? state.likes - 1 : state.likes + 1;

    // optimistic UI
    state = state.copyWith(isLiked: newLiked, likes: newLikes);

    try {
      await PostActions.toggleLike(postId);
    } catch (_) {
      // revert on error
      state = state.copyWith(
        isLiked: wasLiked,
        likes: state.likes + (wasLiked ? 1 : -1),
      );
    }
  }

  @override
  void dispose() {
    _likesChan?.unsubscribe();
    _commentsChan?.unsubscribe();
    super.dispose();
  }
}

final postRealtimeProvider =
    StateNotifierProvider.family<
      PostRealtimeController,
      PostRealtimeState,
      String
    >((ref, postId) => PostRealtimeController(postId));
