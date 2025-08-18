import 'package:flutter/material.dart';
import '../../../../core/net_image.dart';

class Avatar extends StatelessWidget {
  final String url;
  final double size;
  final bool ring;
  const Avatar({
    super.key,
    required this.url,
    this.size = 38, // your default
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = ClipOval(
      child: NetImage(
        url: url,
        width: size,
        height: size,
        fallback: CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.grey.shade400,
          child: const Icon(Icons.person, size: 16, color: Colors.white),
        ),
      ),
    );

    if (!ring) return content;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF76B1C), Color(0xFFF9BF51)],
        ),
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: content,
      ),
    );
  }
}
