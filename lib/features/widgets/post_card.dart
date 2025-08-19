import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/spacing.dart';
import '../../../models/post.dart';
import '../../../services/post_repo.dart';
import '../../../state/video_coordinator.dart';
import 'avatar.dart';
import 'action_bar.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  static const double _mediaMaxH = 420;

  VideoPlayerController? _vc;

  PageController? _imagePager;
  int _imgIndex = 0;

  @override
  void initState() {
    super.initState();
    _initVideoIfNeeded();
    _initPagerIfNeeded();

    // başka bir kart video oynatınca bu kart pause olsun
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

  // ---- helpers ----
  void _safeSnack(String msg) {
    if (!context.mounted) return; // <-- lint mutlu
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _postLink(String id) => 'yourapp://post/$id';

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
                          _safeSnack('Post deleted');
                        } on PostgrestException catch (e) {
                          _safeSnack('Delete failed: ${e.message}');
                        } catch (e) {
                          _safeSnack('Delete failed: $e');
                        }
                        break;

                      case 'copy':
                        final link = _postLink(post.id);
                        await Clipboard.setData(ClipboardData(text: link));
                        _safeSnack('Link copied');
                        break;

                      case 'report':
                        _safeSnack('Thanks, we’ll review this.');
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

  Widget _buildVideo(BorderRadius radius) {
    final vc = _vc;
    if (vc == null || !vc.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final ar = vc.value.aspectRatio == 0 ? 16 / 9 : vc.value.aspectRatio;

    return VisibilityDetector(
      key: Key('video-${widget.post.id}'),
      onVisibilityChanged: (info) {
        // ekrandan kaybolunca durdur
        if (info.visibleFraction < 0.2) {
          if (vc.value.isPlaying) vc.pause();
          VideoCoordinator.stopIfCurrent(widget.post.id);
          if (mounted) setState(() {});
        }
      },
      child: ClipRRect(
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _mediaMaxH),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(aspectRatio: ar, child: VideoPlayer(vc)),
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
      ),
    );
  }

  Widget _buildImages(BorderRadius radius, List<String> urls) {
    final pager = _imagePager!;
    final hasMultiple = urls.length > 1;

    // tek görsel → doğal oranı öğrenip uygula
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _mediaMaxH),
          child: _NetworkAspectImage(url: urls.first, fit: BoxFit.cover),
        ),
      );
    }

    // çoklu görsel
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _mediaMaxH),
            child: PageView.builder(
              controller: pager,
              itemCount: urls.length,
              physics: const PageScrollPhysics(),
              onPageChanged: (i) => setState(() => _imgIndex = i),
              itemBuilder: (_, i) =>
                  _NetworkAspectImage(url: urls[i], fit: BoxFit.cover),
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

  Widget _arrowButton({required bool left, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.35),
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

/// Doğal en/boy oranını hesaplayıp uygun AspectRatio ile çizen ağ görseli.
/// fit=cover (varsayılan) kırpmayı azaltır çünkü oran görüntüden okunuyor.
/// Üst parent max yükseklikle sınırlar.
class _NetworkAspectImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  const _NetworkAspectImage({required this.url, required this.fit});

  @override
  State<_NetworkAspectImage> createState() => _NetworkAspectImageState();
}

class _NetworkAspectImageState extends State<_NetworkAspectImage> {
  double? _ratio; // width / height

  @override
  void initState() {
    super.initState();
    final stream = Image.network(
      widget.url,
    ).image.resolve(const ImageConfiguration());
    stream.addListener(
      ImageStreamListener(
        (info, _) {
          final w = info.image.width.toDouble();
          final h = info.image.height.toDouble();
          if (mounted) setState(() => _ratio = (h == 0 ? null : w / h));
        },
        onError: (_, __) {
          // yut
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ratio ?? (16 / 9); // yüklenene kadar makul oran
    return AspectRatio(
      aspectRatio: ratio,
      child: Image.network(
        widget.url,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
      ),
    );
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
