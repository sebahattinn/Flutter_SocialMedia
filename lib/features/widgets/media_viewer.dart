import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class MediaViewer extends StatefulWidget {
  final List<String> imageUrls;
  final String? videoUrl;
  final double height;
  final BorderRadius? borderRadius;

  const MediaViewer({
    super.key,
    required this.imageUrls,
    this.videoUrl,
    this.height = 300,
    this.borderRadius,
  });

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _autoHideTimer;

  List<String> get _allMedia {
    final List<String> media = [...widget.imageUrls];
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      media.add(widget.videoUrl!);
    }
    return media;
  }

  bool get _hasMultipleMedia => _allMedia.length > 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Auto-hide controls after 3.5 seconds
    _startAutoHideTimer();
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _resetAutoHideTimer() {
    setState(() {
      _showControls = true;
    });
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _hideControlsTimer?.cancel();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  bool _isVideo(String url) {
    return url.toLowerCase().contains('.mp4') ||
        url.toLowerCase().contains('.mov') ||
        url.toLowerCase().contains('.avi') ||
        url == widget.videoUrl;
  }

  Widget _buildMedia(String url, int index) {
    if (_isVideo(url)) {
      return _buildVideoPlayer(url);
    } else {
      return _buildImage(url);
    }
  }

  Widget _buildImage(String url) {
    return GestureDetector(
      onTap: _resetAutoHideTimer,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          color: Colors.grey[900],
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: widget.height,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: widget.height,
                color: Colors.grey[900],
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: widget.height,
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 40),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String url) {
    return FutureBuilder<VideoPlayerController>(
      future: _initializeVideoController(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              color: Colors.grey[900],
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              color: Colors.grey[900],
            ),
            child: const Center(
              child: Icon(Icons.error, color: Colors.white, size: 40),
            ),
          );
        }

        final controller = snapshot.data!;
        return GestureDetector(
          onTap: _resetAutoHideTimer,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: widget.height,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                  // Play/Pause button
                  Positioned(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (controller.value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        });
                        _resetAutoHideTimer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<VideoPlayerController> _initializeVideoController(String url) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    controller.setLooping(true);
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    if (_allMedia.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_allMedia.length == 1) {
      return _buildMedia(_allMedia.first, 0);
    }

    return GestureDetector(
      onTap: _resetAutoHideTimer,
      child: Stack(
        children: [
          // PageView for media
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _resetAutoHideTimer();
              },
              itemCount: _allMedia.length,
              itemBuilder: (context, index) {
                return _buildMedia(_allMedia[index], index);
              },
            ),
          ),

          // Navigation arrows (only show if multiple media and controls are visible)
          if (_hasMultipleMedia && _showControls) ...[
            // Left arrow
            if (_currentIndex > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      _resetAutoHideTimer();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

            // Right arrow
            if (_currentIndex < _allMedia.length - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      _resetAutoHideTimer();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],

          // Media indicator dots
          if (_hasMultipleMedia && _showControls)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _allMedia.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),

          // Media counter
          if (_hasMultipleMedia && _showControls)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1}/${_allMedia.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
