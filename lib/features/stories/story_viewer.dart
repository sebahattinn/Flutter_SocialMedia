import 'package:flutter/material.dart';

/// Basit story modeli: kişi başına 1 görsel (StoryStrip öyle yolluyor)
class Story {
  final String username;
  final String avatarUrl;
  final List<String> images;
  const Story({
    required this.username,
    required this.avatarUrl,
    required this.images,
  });
}

/// Kişiler arası geçiş: ok butonları + (istersen) swipe.
/// [stories] = tüm hikâyeler, [initialIndex] = hangi kişiyle açılacak.
class StoryViewer extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewer({super.key, required this.stories, this.initialIndex = 0});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late final PageController _outer = PageController(
    initialPage: widget.initialIndex,
  );

  late int _current = widget.initialIndex;

  bool get _hasPrev => _current > 0;
  bool get _hasNext => _current < widget.stories.length - 1;

  Future<void> _goPrev() async {
    if (!_hasPrev) return;
    await _outer.animateToPage(
      _current - 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goNext() async {
    if (!_hasNext) return;
    await _outer.animateToPage(
      _current + 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _outer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // KİŞİLER ARASI GÖRÜNÜM
            PageView.builder(
              controller: _outer,
              onPageChanged: (i) => setState(() => _current = i),
              itemCount: widget.stories.length,
              itemBuilder: (_, personIdx) {
                final s = widget.stories[personIdx];
                return _SingleStory(user: s);
              },
            ),

            // KAPAT
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Kapat',
              ),
            ),

            // SOL OK (varsa)
            if (_hasPrev)
              _buildArrow(
                alignment: Alignment.centerLeft,
                icon: Icons.chevron_left,
                onTap: _goPrev,
              ),

            // SAĞ OK (varsa)
            if (_hasNext)
              _buildArrow(
                alignment: Alignment.centerRight,
                icon: Icons.chevron_right,
                onTap: _goNext,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrow({
    required Alignment alignment,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ClipOval(
          child: Material(
            color: Colors.white24, // şeffaf daire
            child: InkWell(
              onTap: onTap,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.chevron_right, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ),
    ).buildWithIcon(icon);
  }
}

// Küçük bir extension ile ikon değiştirelim
extension _ArrowIcon on Widget {
  Widget buildWithIcon(IconData icon) {
    if (this is Align) {
      final align = this as Align;
      final mat = align.child as Padding;
      final clip = mat.child as ClipOval;
      final material = clip.child as Material;
      final ink = material.child as InkWell;
      final sized = ink.child as SizedBox;
      return Align(
        alignment: align.alignment,
        child: Padding(
          padding: mat.padding,
          child: ClipOval(
            child: Material(
              color: material.color!,
              child: InkWell(
                onTap: ink.onTap,
                child: SizedBox(
                  width: sized.width,
                  height: sized.height,
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return this;
  }
}

/// Tek kişinin tek görseli.
/// İçeride ekstra dokunma/gezinti yok; kişi değişimi üst oklarla yapılıyor.
class _SingleStory extends StatelessWidget {
  final Story user;
  const _SingleStory({required this.user});

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.images.first; // tek görsel kabulü

    return Stack(
      children: [
        // FOTO
        Positioned.fill(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (c, child, evt) => evt == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
            ),
          ),
        ),

        // ÜST BAR: tek progress + kullanıcı
        Positioned(
          top: 8,
          left: 48, // soldaki X ile çakışmasın
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // tek segment progress bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
                  const SizedBox(width: 8),
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
