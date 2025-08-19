import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/spacing.dart';
import '../../../models/post.dart';
import 'avatar.dart';
import 'action_bar.dart'; // <-- ActionBar(postId: ...) sürümü

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  VideoPlayerController? _vc;

  @override
  void initState() {
    super.initState();
    if (widget.post.hasVideo) {
      _vc = VideoPlayerController.networkUrl(Uri.parse(widget.post.videoUrl!))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final radius = BorderRadius.circular(16);

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
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
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
            child: ActionBar(
              postId: post.id, // <-- tek gereken bu
              shares: post.shares, // (şimdilik mock)
            ),
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
    return ClipRRect(
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
              onPressed: () =>
                  setState(() => vc.value.isPlaying ? vc.pause() : vc.play()),
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
    );
  }

  Widget _buildImages(BorderRadius radius, List<String> urls) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(urls.first, fit: BoxFit.cover),
        ),
      );
    }

    final controller = PageController();
    return ClipRRect(
      borderRadius: radius,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: controller,
              itemCount: urls.length,
              itemBuilder: (_, i) => Image.network(urls[i], fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 6),
          _Dots(controller: controller, length: urls.length),
          const SizedBox(height: 6),
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
