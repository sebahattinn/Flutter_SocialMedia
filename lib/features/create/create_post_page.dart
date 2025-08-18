import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../services/supabase_service.dart';
import '../../state/feed_controller.dart';
import '../../state/nav_controller.dart';
import '../../models/post.dart';
import '../../models/mock_data.dart' as mock;

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});
  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _text = TextEditingController();

  // Çoklu görsel
  final List<XFile> _pickedImages = [];
  final List<Uint8List> _previewBytes = []; // web için
  final List<File> _previewFiles = []; // mobile/desktop için

  // Tek video
  XFile? _pickedVideo;
  Duration? _videoDuration; // 10 sn kuralı için (mobil/desktop)
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _hasImages => _pickedImages.isNotEmpty;
  bool get _hasVideo => _pickedVideo != null;

  @override
  Widget build(BuildContext context) {
    final canPost =
        !_busy && (_hasImages || _hasVideo || _text.text.trim().isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _text,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Share something...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_hasImages) _buildImagesPreview(),
            if (_hasVideo) _buildVideoPreview(),

            Row(
              children: [
                // Çoklu görsel seç
                ElevatedButton.icon(
                  onPressed: _busy || _hasVideo ? null : _selectPhotos,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Select Photos'),
                ),
                const SizedBox(width: 8),
                // Tek video seç
                ElevatedButton.icon(
                  onPressed: _busy || _hasImages ? null : _selectVideo,
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Select Video'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: canPost ? _post : _needContent,
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

  Widget _buildImagesPreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: PageView.builder(
            itemCount: _pickedImages.length,
            itemBuilder: (_, i) {
              if (kIsWeb) {
                return Image.memory(_previewBytes[i], fit: BoxFit.cover);
              } else {
                return Image.file(_previewFiles[i], fit: BoxFit.cover);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.videocam, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(_pickedVideo!.name)),
            if (_videoDuration != null)
              Text(
                '${_videoDuration!.inSeconds}s',
                style: const TextStyle(color: Colors.grey),
              ),
            IconButton(
              tooltip: 'Remove',
              onPressed: _busy ? null : _clearVideo,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPhotos() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 92);
      if (files.isEmpty) return;

      _pickedImages
        ..clear()
        ..addAll(files);
      _previewBytes.clear();
      _previewFiles.clear();

      if (kIsWeb) {
        for (final f in files) {
          _previewBytes.add(await f.readAsBytes());
        }
      } else {
        for (final f in files) {
          _previewFiles.add(File(f.path));
        }
      }
      setState(() {});
    } catch (e) {
      _snack('Görseller seçilemedi: $e');
    }
  }

  Future<void> _selectVideo() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 15),
      );
      if (file == null) return;

      // 10 sn kontrolü (mobil/desktop)
      if (!kIsWeb) {
        final ctrl = VideoPlayerController.file(File(file.path));
        await ctrl.initialize();
        final d = ctrl.value.duration;
        await ctrl.dispose();

        if (d > const Duration(seconds: 10)) {
          _snack('Video 10 saniyeyi geçemez.');
          return;
        }
        _videoDuration = d;
      } else {
        _videoDuration = null; // web'de client-side güvenilir değil
      }

      _pickedVideo = file;
      setState(() {});
    } catch (e) {
      _snack('Video seçilemedi: $e');
    }
  }

  void _clearVideo() {
    _pickedVideo = null;
    _videoDuration = null;
    setState(() {});
  }

  Future<void> _post() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      // Aynı anda hem video hem görsel gönderme
      if (_hasImages && _hasVideo) {
        _snack('Aynı gönderide ya çoklu görsel ya da tek video seçebilirsin.');
        setState(() => _busy = false);
        return;
      }

      final text = _text.text.trim();
      List<String> imageUrls = [];
      String? videoUrl;

      // Görselleri yükle (güvenli path)
      if (_hasImages) {
        for (int i = 0; i < _pickedImages.length; i++) {
          final f = _pickedImages[i];
          final ext = _safeExt(f.name, fallback: 'jpg');
          final path = _safeName(dir: 'images', ext: ext, index: i);

          if (kIsWeb) {
            final bytes = _previewBytes[i];
            imageUrls.add(
              await SupabaseService.upload(
                bucket: 'media',
                path: path,
                fileOrBytes: bytes,
                // contentType boş bırak -> SupabaseService path uzantısından tahmin ediyor
              ),
            );
          } else {
            final file = _previewFiles[i];
            imageUrls.add(
              await SupabaseService.upload(
                bucket: 'media',
                path: path,
                fileOrBytes: file,
              ),
            );
          }
        }
      }

      // Videoyu yükle (güvenli path)
      if (_hasVideo) {
        final f = _pickedVideo!;
        final ext = _safeExt(f.name, fallback: 'mp4');
        final path = _safeName(dir: 'videos', ext: ext);

        if (kIsWeb) {
          final bytes = await f.readAsBytes();
          videoUrl = await SupabaseService.upload(
            bucket: 'media',
            path: path,
            fileOrBytes: bytes,
          );
        } else {
          videoUrl = await SupabaseService.upload(
            bucket: 'media',
            path: path,
            fileOrBytes: File(f.path),
          );
        }
      }

      if (imageUrls.isEmpty &&
          (videoUrl == null || videoUrl.isEmpty) &&
          text.isEmpty) {
        _snack('Önce bir şey yaz, fotoğraf ya da video ekle.');
        setState(() => _busy = false);
        return;
      }

      final p = Post(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        author: mock.users[0],
        text: text,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        createdAt: DateTime.now(),
      );

      ref.read(feedProvider.notifier).addLocalPost(p);
      ref.read(navIndexProvider.notifier).state = 0;

      _reset();
      _snack(
        videoUrl != null
            ? 'Video paylaşıldı'
            : (imageUrls.isNotEmpty
                  ? 'Fotoğraflar paylaşıldı'
                  : 'Gönderi paylaşıldı'),
      );
    } catch (e) {
      _snack('Paylaşım başarısız: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    _text.clear();
    _pickedImages.clear();
    _previewBytes.clear();
    _previewFiles.clear();
    _pickedVideo = null;
    _videoDuration = null;
    setState(() {});
  }

  void _needContent() => _snack('Önce bir şey yaz veya medya ekle.');

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// Yalnızca güvenli uzantıları kabul et (fallback ver)
String _safeExt(String name, {required String fallback}) {
  final dot = name.lastIndexOf('.');
  if (dot == -1) return fallback;
  final ext = name.substring(dot + 1).toLowerCase();
  const allowed = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov'};
  return allowed.contains(ext) ? ext : fallback;
}


String _safeName({required String dir, required String ext, int? index}) {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final idx = index != null ? '_$index' : '';
  return '$dir/$ts$idx.$ext';
}
