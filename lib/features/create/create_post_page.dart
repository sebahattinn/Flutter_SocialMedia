import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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

  XFile? _picked; // seçilen medya (şimdilik foto)
  Uint8List? _previewBytes; // web önizleme
  File? _previewFile; // mobile/desktop önizleme
  bool _busy = false; // upload/post sırasında kilitle

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPost = !_busy && (_picked != null || _text.text.trim().isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _text,
              maxLines: 5,
              onChanged: (_) => setState(() {}), // butonu canlı tut
              decoration: InputDecoration(
                hintText: "Share something...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Önizleme
            if (_picked != null) _buildPreview(),

            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _selectPhoto, // sadece seçer
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Select Photo'),
                ),
                const SizedBox(width: 8),
                if (_picked != null)
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: _busy ? null : _clearSelection,
                    icon: const Icon(Icons.close),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: canPost ? _post : _showNeedContent,
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

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: kIsWeb
              ? Image.memory(_previewBytes!, fit: BoxFit.cover)
              : Image.file(_previewFile!, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Future<void> _selectPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (file == null) return;

      _picked = file;
      if (kIsWeb) {
        _previewBytes = await file.readAsBytes();
        _previewFile = null;
      } else {
        _previewFile = File(file.path);
        _previewBytes = null;
      }
      setState(() {});
    } catch (e) {
      _snack('Fotoğraf seçilemedi: $e');
    }
  }

  void _clearSelection() {
    _picked = null;
    _previewBytes = null;
    _previewFile = null;
    setState(() {});
  }

  Future<void> _post() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      String? imageUrl;
      final text = _text.text.trim();

      // Fotoğraf seçildiyse önce upload et
      if (_picked != null) {
        final path =
            'public/images/${DateTime.now().millisecondsSinceEpoch}_${_picked!.name}';

        if (kIsWeb) {
          final bytes = _previewBytes ?? await _picked!.readAsBytes();
          imageUrl = await SupabaseService.upload(
            bucket: 'media',
            path: path,
            fileOrBytes: bytes,
            contentType: 'image/jpeg',
          );
        } else {
          final f = _previewFile ?? File(_picked!.path);
          imageUrl = await SupabaseService.upload(
            bucket: 'media',
            path: path,
            fileOrBytes: f,
            contentType: 'image/jpeg',
          );
        }
      }

      // Hem text hem image boşsa engelle
      if ((imageUrl == null || imageUrl.isEmpty) && text.isEmpty) {
        _snack('Önce bir şey yaz veya fotoğraf ekle.');
        setState(() => _busy = false);
        return;
      }

      // Post nesnesini oluştur
      final p = Post(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        author: mock.users[0],
        text: text,
        imageUrl: imageUrl, // sadece text ise null kalır
        createdAt: DateTime.now(),
      );

      // Feed’e ekle
      ref.read(feedProvider.notifier).addLocalPost(p);

      // Home (Feed) sekmesine dön
      ref.read(navIndexProvider.notifier).state = 0;

      // Temizlik + bildirim
      _text.clear();
      _clearSelection();
      _snack(imageUrl != null ? 'Fotoğraf paylaşıldı' : 'Gönderi paylaşıldı');
    } catch (e) {
      _snack('Paylaşım başarısız: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showNeedContent() {
    _snack('Önce bir şey yaz veya fotoğraf ekle.');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
