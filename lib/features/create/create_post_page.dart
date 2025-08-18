import 'package:flutter/material.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              maxLines: 6,
              decoration: InputDecoration(
                hintText: "Share something...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Photo'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Video'),
                ),
                const Spacer(),
                FilledButton(onPressed: () {}, child: const Text('Post')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
