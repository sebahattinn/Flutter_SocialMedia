import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../../../core/spacing.dart';
import '../../../models/post.dart';
import '../../../services/post_repo.dart';
import '../../../state/video_coordinator.dart'; // <--- EKLEDİK
import 'avatar.dart';
import 'action_bar.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  VideoPlayerController? _vc;

  PageController? _imagePager;
  int _imgIndex = 0;

  @override
  void initState() {
    super.initState();
    _initVideoIfNeeded();
    _initPagerIfNeeded();

    // Başka bir kart oynatmaya başlarsa bu kart pause olsun
    VideoCoordinator.current.addListener(_onGlobalPlayChanged);
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.videoUrl != widget.post.videoUrl) {
      _disposeVideo();
      _initVideoIfNeeded();
    }
    if (oldWidget.post.imageUrls != widget.post.imageUrls) {
      _disposePager();
      _initPagerIfNeeded();
    }
  }

  void _onGlobalPlayChanged() {
    final current = VideoCoordinator.current.value;
    final mine = current == widget.post.id;
    final vc = _vc;
    if (vc == null) return;

    // Başkası çalıyorsa ben durayım
    if (!mine && vc.value.isPlaying) {
      vc.pause();
      if (mounted) setState(() {});
    }
  }

  void _initVideoIfNeeded() {
    if (widget.post.hasVideo) {
      _vc = VideoPlayerController.networkUrl(Uri.parse(widget.post.videoUrl!))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  void _disposeVideo() {
    _vc?.dispose();
    _vc = null;
  }

  void _initPagerIfNeeded() {
    if (widget.post.hasImages) {
      _imagePager = PageController();
      _imgIndex = 0;
    }
  }

  void _disposePager() {
    _imagePager?.dispose();
    _imagePager = null;
    _imgIndex = 0;
  }

  @override
  void dispose() {
    VideoCoordinator.stopIfCurrent(widget.post.id);
    VideoCoordinator.current.removeListener(_onGlobalPlayChanged);
    _disposeVideo();
    _disposePager();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final radius = BorderRadius.circular(16);
    final isMine = post.author.id == PostRepo.devUserId;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Avatar(url: post.author.avatarUrl, ring: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '@${post.author.handle} • ${_timeAgo(post.createdAt)}',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) async {
                    switch (value) {
                      case 'delete':
                        final ok =
                            await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete post?'),
                                content: const Text(
                                  'This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (!ok) return;

                        try {
                          await PostRepo.deletePost(post.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post deleted')),
                          );
                        } on PostgrestException catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Delete failed: ${e.message}'),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Delete failed: $e')),
                          );
                        }
                        break;

                      case 'copy':
                        final link = _postLink(post.id);
                        await Clipboard.setData(ClipboardData(text: link));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied')),
                        );
                        break;

                      case 'report':
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thanks, we’ll review this.'),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (_) => isMine
                      ? const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline),
                                SizedBox(width: 8),
                                Text('Delete post'),
                              ],
                            ),
                          ),
                        ]
                      : const [
                          PopupMenuItem(
                            value: 'copy',
                            child: Row(
                              children: [
                                Icon(Icons.link),
                                SizedBox(width: 8),
                                Text('Copy link'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.flag_outlined),
                                SizedBox(width: 8),
                                Text('Report'),
                              ],
                            ),
                          ),
                        ],
                ),
              ],
            ),
          ),

          // TEXT
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.text,
                style: const TextStyle(fontSize: 15, height: 1.35),
              ),
            ),

          // MEDIA
          if (post.hasVideo) ...[
            gap12,
            _buildVideo(radius),
          ] else if (post.hasImages) ...[
            gap12,
            _buildImages(radius, post.imageUrls),
          ] else
            gap12,

          // ACTIONS
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: ActionBar(postId: post.id, shares: post.shares),
          ),
        ],
      ),
    );
  }

  String _postLink(String id) => 'yourapp://post/$id';

  Widget _buildVideo(BorderRadius radius) {
    final vc = _vc;
    if (vc == null || !vc.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return VisibilityDetector(
      key: Key('video-${widget.post.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction < 0.2) {
          // ekrandan çıktı → durdur ve koordinatoru temizle
          if (vc.value.isPlaying) {
            vc.pause();
          }
          VideoCoordinator.stopIfCurrent(widget.post.id);
          if (mounted) setState(() {});
        }
      },
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: vc.value.aspectRatio,
              child: VideoPlayer(vc),
            ),
            Material(
              color: Colors.transparent,
              child: IconButton(
                iconSize: 56,
                onPressed: () {
                  setState(() {
                    if (vc.value.isPlaying) {
                      vc.pause();
                      VideoCoordinator.stopIfCurrent(widget.post.id);
                    } else {
                      // ben oynayacağım → diğer kartlar listener ile pause olacak
                      VideoCoordinator.requestPlay(widget.post.id);
                      vc.play();
                    }
                  });
                },
                icon: Icon(
                  vc.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arrowButton({required bool left, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(6),
        child: Icon(
          left ? Icons.chevron_left : Icons.chevron_right,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildImages(BorderRadius radius, List<String> urls) {
    final pager = _imagePager ?? PageController();
    final hasMultiple = urls.length > 1;

    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(urls.first, fit: BoxFit.cover),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: pager,
              itemCount: urls.length,
              physics: const PageScrollPhysics(),
              onPageChanged: (i) => setState(() => _imgIndex = i),
              itemBuilder: (_, i) => Image.network(urls[i], fit: BoxFit.cover),
            ),
          ),

          if (hasMultiple && _imgIndex > 0)
            Positioned(
              left: 8,
              child: _arrowButton(
                left: true,
                onTap: () {
                  final next = (_imgIndex - 1).clamp(0, urls.length - 1);
                  pager.animateToPage(
                    next,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),

          if (hasMultiple && _imgIndex < urls.length - 1)
            Positioned(
              right: 8,
              child: _arrowButton(
                left: false,
                onTap: () {
                  final next = (_imgIndex + 1).clamp(0, urls.length - 1);
                  pager.animateToPage(
                    next,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),

          Positioned(
            bottom: 6,
            child: _Dots(controller: pager, length: urls.length),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _Dots extends StatefulWidget {
  final PageController controller;
  final int length;
  const _Dots({required this.controller, required this.length});

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> {
  double _page = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (mounted) setState(() => _page = widget.controller.page ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (i) {
        final active = (i - _page).abs() < .5;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 16 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? Colors.white70 : Colors.white24,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
