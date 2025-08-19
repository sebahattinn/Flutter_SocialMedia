// lib/features/create/create_post_page.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/supabase_service.dart';
import '../../services/post_repo.dart';
import '../../state/nav_controller.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});
  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _text = TextEditingController();
  List<XFile> _images = [];
  XFile? _video;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 92);
    if (files.isNotEmpty) {
      setState(() {
        _images = files.take(10).toList();
        _video = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final v = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 10),
    );
    if (v != null) {
      setState(() {
        _video = v;
        _images = [];
      });
    }
  }

  Future<void> _post() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final text = _text.text.trim();

      // 1) Storage upload
      final imageUrls = <String>[];
      for (final img in _images) {
        final safeName = SupabaseService.sanitizeFileName(img.name);
        final path = SupabaseService.joinPath(
          'images',
          '${DateTime.now().millisecondsSinceEpoch}_$safeName',
        );

        String url;
        if (kIsWeb) {
          final bytes = await img.readAsBytes();
          url = await SupabaseService.upload(
            bucket: 'media',
            path: path,
            fileOrBytes: bytes,
            contentType: 'image/jpeg',
          );
        } else {
          url = await SupabaseService.upload(
            bucket: 'media',
            path: path,
            fileOrBytes: File(img.path),
            contentType: 'image/jpeg',
          );
        }
        imageUrls.add(url);
      }

      String? videoUrl;
      if (_video != null) {
        final safeName = SupabaseService.sanitizeFileName(_video!.name);
        final path = SupabaseService.joinPath(
          'videos',
          '${DateTime.now().millisecondsSinceEpoch}_$safeName',
        );

        if (kIsWeb) {
          final bytes = await _video!.readAsBytes();
          videoUrl = await SupabaseService.upload(
            bucket: 'media',
            path: path,
            fileOrBytes: bytes,
            contentType: 'video/mp4',
          );
        } else {
          videoUrl = await SupabaseService.upload(
            bucket: 'media',
            path: path,
            fileOrBytes: File(_video!.path),
            contentType: 'video/mp4',
          );
        }
      }

      // 2) DB (dev amaçlı sabit author)
      await PostRepo.createPostDev(
        text: text.isEmpty ? null : text,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
      );

      // 3) Feed'e dön; stream yeni postu otomatik getirir
      ref.read(navIndexProvider.notifier).state = 0;

      if (mounted) {
        _text.clear();
        _images = [];
        _video = null;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gönderi paylaşıldı')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Paylaşım başarısız: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = _images.isNotEmpty;
    final hasVideo = _video != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _text,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Share something...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (hasImages) ...[
              AspectRatio(
                aspectRatio: 16 / 9,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _images.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (_, i) {
                    final f = _images[i];
                    if (kIsWeb) {
                      return Image.network(f.path, fit: BoxFit.cover);
                    } else {
                      return Image.file(File(f.path), fit: BoxFit.cover);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.image),
                  const SizedBox(width: 8),
                  Text('${_images.length} photo(s) selected'),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _images = []),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ] else if (hasVideo) ...[
              Row(
                children: [
                  const Icon(Icons.videocam),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_video!.name, overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _video = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Select Photos'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _pickVideo,
                  icon: const Icon(Icons.movie_creation_outlined),
                  label: const Text('Select Video'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _post,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
