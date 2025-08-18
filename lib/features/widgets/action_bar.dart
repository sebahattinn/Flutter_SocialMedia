import 'package:flutter/material.dart';
import '../../../../core/formatters.dart';

class ActionBar extends StatelessWidget {
  final int likes;
  final int comments;
  final int shares;
  const ActionBar({
    super.key,
    required this.likes,
    required this.comments,
    required this.shares,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconText(icon: Icons.favorite_border, label: compactNumber(likes)),
        const SizedBox(width: 16),
        _IconText(
          icon: Icons.mode_comment_outlined,
          label: compactNumber(comments),
        ),
        const SizedBox(width: 16),
        _IconText(icon: Icons.share_outlined, label: compactNumber(shares)),
        const Spacer(),
        IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border)),
      ],
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconText({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
