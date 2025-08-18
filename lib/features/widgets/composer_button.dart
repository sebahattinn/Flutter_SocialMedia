import 'package:flutter/material.dart';

class ComposerButton extends StatelessWidget {
  const ComposerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1D1D) : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEDEDED),
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=64'),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "What's on your mind?",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.image_outlined),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.videocam_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
