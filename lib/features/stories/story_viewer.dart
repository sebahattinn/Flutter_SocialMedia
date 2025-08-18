import 'package:flutter/material.dart';

class StoryViewer extends StatelessWidget {
  final String username;
  final String avatarUrl;
  final List<String> images;

  const StoryViewer({
    super.key,
    required this.username,
    required this.avatarUrl,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              itemBuilder: (_, i) => Image.network(
                images[i],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Row(
                children: [
                  CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
                  const SizedBox(width: 8),
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
