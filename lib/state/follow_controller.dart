import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Usage in ProfilePage:
/// final s = ref.watch(followControllerProvider(FollowIds(me: '<uuid>', target: '<uuid>')));
final followControllerProvider = StateNotifierProvider.autoDispose
    .family<FollowController, FollowState, FollowIds>((ref, ids) {
      final c = FollowController(ids);
      ref.onDispose(c.dispose); // extra safety
      return c;
    });

/* IDs for "current user" and "profile being viewed" */
class FollowIds {
  final String me; // current user id
  final String target; // profile being viewed
  const FollowIds({required this.me, required this.target});
}

class FollowState {
  final int followers;
  final int following;
  final bool isFollowing;
  final bool loading;
  final String? error;

  const FollowState({
    this.followers = 0,
    this.following = 0,
    this.isFollowing = false,
    this.loading = false,
    this.error,
  });

  FollowState copyWith({
    int? followers,
    int? following,
    bool? isFollowing,
    bool? loading,
    String? error, // set null to clear
  }) => FollowState(
    followers: followers ?? this.followers,
    following: following ?? this.following,
    isFollowing: isFollowing ?? this.isFollowing,
    loading: loading ?? this.loading,
    error: error,
  );
}

class FollowController extends StateNotifier<FollowState> {
  final FollowIds ids;
  final SupabaseClient s = Supabase.instance.client;
  RealtimeChannel? _chan;
  bool _disposed = false;

  FollowController(this.ids) : super(const FollowState()) {
    _bootstrap();
  }

  /* ------------------------------ lifecycle ------------------------------ */

  Future<void> _bootstrap() async {
    await _refresh();
    _subscribeFiltered();
  }

  void _subscribeFiltered() {
    // unsubscribe if any
    _chan?.unsubscribe();

    // Subscribe ONLY to follow/unfollow events where followee == target
    _chan = s
        .channel('public:follows:${ids.target}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'follows',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'followee',
            value: ids.target,
          ),
          callback: (payload) {
            if (kDebugMode) {
              print('realtime insert: ${payload.newRecord}');
            }
            _refresh();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'follows',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'followee',
            value: ids.target,
          ),
          callback: (payload) {
            if (kDebugMode) {
              print('realtime delete: ${payload.oldRecord}');
            }
            _refresh();
          },
        )
        .subscribe();
  }

  /// Optional helper: call this once from UI if you want to **debug Realtime**
  /// without any filters (see everything hitting `public.follows`).
  void subscribeAllForDebug() {
    _chan?.unsubscribe();
    _chan = s
        .channel('public:follows:ALL')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'follows',
          callback: (payload) {
            if (kDebugMode) {
              print(
                'realtime all -> ${payload.eventType} '
                'new=${payload.newRecord} old=${payload.oldRecord}',
              );
            }
            _refresh();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _disposed = true;
    _chan?.unsubscribe();
    super.dispose();
  }

  /* -------------------------------- queries ------------------------------- */

  Future<void> _refresh() async {
    _setState(state.copyWith(loading: true, error: null));
    try {
      // Count followers (rows where followee == target)
      final followersRows = await s
          .from('follows')
          .select('follower')
          .eq('followee', ids.target);
      final followers = (followersRows as List).length;

      // Count following (rows where follower == target)
      final followingRows = await s
          .from('follows')
          .select('followee')
          .eq('follower', ids.target);
      final following = (followingRows as List).length;

      // Is "me" following "target"?
      final rel = await s
          .from('follows')
          .select('followee')
          .eq('follower', ids.me)
          .eq('followee', ids.target)
          .maybeSingle();

      final isFollowing = rel != null;

      _setState(
        state.copyWith(
          followers: followers,
          following: following,
          isFollowing: isFollowing,
          loading: false,
          error: null,
        ),
      );
    } catch (e) {
      _setState(state.copyWith(loading: false, error: e.toString()));
    }
  }

  /* ------------------------------ mutations ------------------------------ */

  Future<void> toggleFollow() async {
    // Optimistic update for snappy UI
    if (state.isFollowing) {
      _setState(
        state.copyWith(
          isFollowing: false,
          followers: (state.followers - 1).clamp(0, 1 << 31),
        ),
      );
      try {
        await s
            .from('follows')
            .delete()
            .eq('follower', ids.me)
            .eq('followee', ids.target);
      } catch (e) {
        // revert on failure
        _setState(
          state.copyWith(
            isFollowing: true,
            followers: state.followers + 1,
            error: e.toString(),
          ),
        );
      }
    } else {
      _setState(
        state.copyWith(isFollowing: true, followers: state.followers + 1),
      );
      try {
        await s.from('follows').insert({
          'follower': ids.me,
          'followee': ids.target,
        });
      } catch (e) {
        // primary key conflict or network error -> revert
        _setState(
          state.copyWith(
            isFollowing: false,
            followers: (state.followers - 1).clamp(0, 1 << 31),
            error: e.toString(),
          ),
        );
      }
    }

    // final truth from DB (also triggered by realtime, but good to re-sync)
    await _refresh();
  }

  /* ------------------------------ utilities ------------------------------ */

  void _setState(FollowState next) {
    if (_disposed) return;
    state = next;
  }
}
